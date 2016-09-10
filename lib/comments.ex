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

  @doc """
  Parses a comment into an attachment for Slack.

  ## Example
  """
  def parse_comment(comment, checkin) do
    %{
      # "author_icon" => user_avatar,
      # "author_link" => "https://untappd.com/user/#{user_username}",
      # "author_name" => user_username,
      # "color" => "#FFCF0B",
      # "fallback" => "Image of this checkin.",
      # "footer" => "<https://untappd.com/brewery/#{brewery_id}|#{brewery_name}>",
      # "footer_icon" => brewery_label,
      # "image_url" => image_url,
      # "text" => text,
      # "title" => beer_name,
      # "title_link" => "https://untappd.com/b/#{beer_slug}/#{beer_id}"
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

    @redis.command("SET #{@instance_name}:comment-#{comment_id} 1")

    {:ok, comment}
  end
end
