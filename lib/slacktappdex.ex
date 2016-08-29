defmodule Slacktappdex do
  @slack Application.get_env(:slacktappdex, :slack)
  @untappd Application.get_env(:slacktappdex, :untappd)

  def main() do
    checkins
      |> Enum.each(fn(checkin) ->
        checkin
          |> process_checkin
          |> process_badges
          |> process_comments
      end)
  end

  def checkins() do
    @untappd.get("checkin/recent")
     |> Map.fetch!(:body)
     |> Poison.decode!
     |> get_in(["response", "checkins", "items"])
  end

  def parse_badge(badge) do
    "badge"
  end

  def parse_checkin(checkin) do
    "checkin"
  end

  def parse_comment(comment) do
    "comment"
  end

  defp process_badge(badge) do
    parse_badge(badge) |> @slack.post
    badge
  end

  defp process_checkin(checkin) do
    parse_checkin(checkin) |> @slack.post
    checkin
  end

  defp process_comment(comment) do
    parse_comment(comment) |> @slack.post
    comment
  end

  defp process_badges(checkin) do
    get_in(checkin, ["badges", "items"])
      |> Enum.each(&(process_badge(&1)))
    checkin
  end

  defp process_comments(checkin) do
    get_in(checkin, ["comments", "items"])
      |> Enum.each(&(process_comment(&1)))
    checkin
  end
end
