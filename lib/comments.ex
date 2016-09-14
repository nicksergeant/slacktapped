defmodule Slacktapped.Comments do
  @instance_name System.get_env("INSTANCE_NAME") ||
    Application.get_env(:slacktapped, :instance_name)
  @redis Application.get_env(:slacktapped, :redis)

  @doc """
  Processes a checkins comments.

  Loops through all comments and determines if they are eligible to be
  posted to Slack. If they are, they're processed and added to the
  checkins attachments.
  """
  def process_comments(checkin) do
    if is_map(checkin["comments"]) do
      get_in(checkin, ["comments", "items"])
        |> Enum.reduce([], fn(comment, acc) ->
            if is_eligible_comment(comment) do
              acc ++ [process_comment(comment, checkin)]
            else
              acc
            end
          end)
        |> Slacktapped.Utils.add_attachments(checkin)
    else
      {:ok, checkin}
    end
  end

  @doc """
  Reports the comment as posted to Redis, and returns a parsed comment as
  an attachment for Slack.
  """
  def process_comment(comment, checkin) do
    report_comment(comment)
    parse_comment(comment, checkin)
  end

  @doc """
  Determines if a comment is eligible to be posted to Slack.

  Comment is ineligible if we have already posted it to Slack.

  ## Examples

      iex> Slacktapped.Comments.is_eligible_comment(%{"comment_id" => 3344})
      true

      iex> Slacktapped.Comments.is_eligible_comment(%{"comment_id" => 3355})
      false

  """
  def is_eligible_comment(comment) do
    comment_id = comment["comment_id"]
    get_key = "GET #{@instance_name}:comment-#{comment_id}"

    @redis.command("#{get_key}") == {:ok, nil}
  end

  @doc ~S"""
  Parses a comment into an attachment for Slack.

  ## Example

      iex> Slacktapped.Comments.parse_comment(
      ...> %{
      ...>   "comment_id" => 3593,
      ...>   "comment" => "Great beer!",
      ...>   "user" => %{
      ...>     "first_name" => "George",
      ...>     "last_name" => "C.",
      ...>     "user_link" => "http://path/to/comment/user",
      ...>     "user_name" => "george"
      ...>   }
      ...> },
      ...> %{
      ...>   "attachments" => [],
      ...>   "user" => %{
      ...>     "user_name" => "nicksergeant",
      ...>     "user_avatar" => "http://path/to/user/avatar"
      ...>   },
      ...>   "beer" => %{
      ...>     "bid" => 123,
      ...>     "beer_name" => "IPA",
      ...>     "beer_slug" => "two-lake-ipa"
      ...>   },
      ...>   "checkin_id" => 567
      ...> })
      %{
        "color" => "#FFCF0B",
        "fallback" => "Checkin comment.",
        "mrkdwn_in" => ["text"],
        "text" => "<http://path/to/comment/user|George C.> commented on " <>
          "<https://untappd.com/user/nicksergeant/checkin/567|nicksergeant's " <>
          "checkin> of <https://untappd.com/b/two-lake-ipa/123|IPA> and " <>
          "said:\n>Great beer!"
      }

  """
  def parse_comment(comment, checkin) do
    c = Slacktapped.Utils.checkin_parts(checkin)

    comment_text = comment["comment"]
    comment_user_link = comment["user"]["user_link"]
    comment_user_name = Slacktapped.Utils.parse_name(comment["user"])

    text = "<#{comment_user_link}|#{comment_user_name}> commented on " <>
      "<#{c.checkin_url}|#{c.user_name}'s checkin> of " <>
      "#{c.beer} and said:\n>#{comment_text}"

    %{
      "color" => "#FFCF0B",
      "mrkdwn_in" => ["text"],
      "fallback" => "Checkin comment.",
      "text" => text
    }
  end

  @doc """
  Reports that a comment was posted to Slack by setting a Redis key.

  ## Example

      iex> Slacktapped.Comments.report_comment(%{"comment_id" => 345})
      {:ok, %{"comment_id" => 345}}

  """
  def report_comment(comment) do
    comment_id = comment["comment_id"]
    expiration = Application.get_env(:slacktapped, :redis_expiration)

    @redis.command("SETEX #{@instance_name}:comment-#{comment_id} #{expiration} 1")

    {:ok, comment}
  end
end
