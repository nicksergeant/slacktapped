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
  """
  def parse_badge(badge, checkin) do
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
