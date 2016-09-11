defmodule Slacktapped.Badges do
  @instance_name System.get_env("INSTANCE_NAME") ||
    Application.get_env(:slacktapped, :instance_name)
  @redis Application.get_env(:slacktapped, :redis)

  @doc """
  Processes a checkins badges.

  Loops through all badges and determines if they are eligible to be
  posted to Slack. If they are, they're processed and added to the
  checkins attachments.
  """
  def process_badges(checkin) do
    if is_map(checkin["badges"]) do
      get_in(checkin, ["badges", "items"])
        |> Enum.reduce([], fn(badge, acc) ->
            if is_eligible_badge(badge) do
              acc ++ [process_badge(badge, checkin)]
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
  Reports the badge as posted to Redis, and returns a parsed badge as
  an attachment for Slack.
  """
  def process_badge(badge, checkin) do
    report_badge(badge)
    parse_badge(badge, checkin)
  end

  @doc """
  Determines if a badge is eligible to be posted to Slack.

  Badge is ineligible if we have already posted it to Slack.

  ## Example

      iex> Slacktapped.Badges.is_eligible_badge(%{"user_badge_id" => 5566})
      true

      iex> Slacktapped.Badges.is_eligible_badge(%{"user_badge_id" => 5533})
      false

  """
  def is_eligible_badge(badge) do
    user_badge_id = badge["user_badge_id"]
    get_key = "GET #{@instance_name}:badge-#{user_badge_id}"

    @redis.command("#{get_key}") == {:ok, nil}
  end

  @doc """
  Parses a badge into an attachment for Slack.

  ## Example

      iex> Slacktapped.Badges.parse_badge(
      ...> %{
      ...>   "badge_name" => "Hopped Up (Level 18)",
      ...>   "user_badge_id" => 3593,
      ...>   "badge_image" => %{
      ...>     "sm" => "http://path/to/badge/image"
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
        "author_icon" => "http://path/to/user/avatar",
        "author_link" => "https://untappd.com/user/nicksergeant",
        "author_name" => "nicksergeant",
        "color" => "#FFCF0B",
        "fallback" => "Checkin badge.",
        "image_url" => "http://path/to/badge/image",
        "text" => "<https://untappd.com/user/nicksergeant|nicksergeant> " <>
          "earned the badge " <>
          "<https://untappd.com/user/nicksergeant/badges/3593|" <>
          "Hopped Up (Level 18)> for " <>
          "<https://untappd.com/user/nicksergeant/checkin/567|their checkin> " <>
          "of <https://untappd.com/b/two-lake-ipa/123|IPA>.",
        "title" => "Hopped Up (Level 18)",
        "title_link" => "https://untappd.com/user/nicksergeant/badges/3593"
      }

  """
  def parse_badge(badge, checkin) do
    c = Slacktapped.Utils.checkin_parts(checkin)

    user_badge_id = badge["user_badge_id"]
    badge_image = badge["badge_image"]["sm"]
    badge_name = badge["badge_name"]
    badge_url = "https://untappd.com/user/#{c.user_username}/badges/#{user_badge_id}"

    text = "#{c.user} earned the badge <#{badge_url}|#{badge_name}> for " <>
      "<#{c.checkin_url}|their checkin> of #{c.beer}."

    %{
      "author_icon" => c.user_avatar,
      "author_link" => c.user_url,
      "author_name" => c.user_username,
      "color" => "#FFCF0B",
      "fallback" => "Checkin badge.",
      "image_url" => badge_image,
      "text" => text,
      "title" => badge_name,
      "title_link" => badge_url
    }
  end

  @doc """
  Reports that a badge was posted to Slack by setting a Redis key.

  ## Example

      iex> Slacktapped.Badges.report_badge(%{"user_badge_id" => 876})
      {:ok, %{"user_badge_id" => 876}}

  """
  def report_badge(badge) do
    user_badge_id = badge["user_badge_id"]

    @redis.command("SET #{@instance_name}:badge-#{user_badge_id} 1")

    {:ok, badge}
  end
end
