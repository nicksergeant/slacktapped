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
        |> Slacktapped.add_attachments(checkin)
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
  """
  def is_eligible_badge(badge) do
    false
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
  """
  def report_badge(badge) do
    # checkin_id = checkin["checkin_id"]
    # media_items = checkin["media"]["items"]
    # has_image = is_list(media_items) and Enum.count(media_items) >= 1

    # reported_as = cond do
    #   has_image == true ->
    #     @redis.command("SET #{@instance_name}:#{checkin_id}:with-image 1")
    #     "with-image"
    #   true ->
    #     @redis.command("SET #{@instance_name}:#{checkin_id}:without-image 1")
    #     "without-image"
    # end

    # checkin = Map.put(checkin, "reported_as", reported_as)

    {:ok, badge}
  end
end
