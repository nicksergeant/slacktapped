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

  @doc """
  Parses a checkin map to a string for Slack.

  ## Examples

      iex> checkin = %{
      iex>   "user" => %{
      iex>     "user_name" => "nicksergeant"
      iex>   }
      iex> }
      iex> Slacktappdex.parse_checkin(checkin)
      "nicksergeant is drinking"

  """
  def parse_checkin(checkin) do
    # TODO: If checkin description has #shh in it, ignore.
    # TODO: Post image if we haven't already, even if checkin already.

    username = get_in(checkin, ["user", "user_name"])

    # """
    #   #{username} is drinking #{beer_name} (#{beer_type}, #{abv} ABV)
    #   by #{brewery}. They rated it a #{rating} and said \"#{comment}\".
    # """
    "#{username} is drinking"
  end

  def parse_comment(comment) do
    "comment"
  end

  @doc """
  Returns the user's name. If both first and last name are present, it returns
  "First-name Last-name", otherwise it returns "username".

  ## Examples

      iex> user = %{
      iex>   "user_name" => "nicksergeant"
      iex> }
      iex> Slacktappdex.parse_username(user)
      "nicksergeant"

      iex> user = %{
      iex>   "user_name" => "nicksergeant",
      iex>   "first_name" => "Nick",
      iex>   "last_name" => "Sergeant"
      iex> }
      iex> Slacktappdex.parse_username(user)
      "Nick Sergeant"

      iex> user = %{
      iex>   "user_name" => "nicksergeant",
      iex>   "first_name" => "Nick"
      iex> }
      iex> Slacktappdex.parse_username(user)
      "nicksergeant"

  """
  def parse_username(user) do
    case user do
      %{
        "first_name" => first_name,
        "last_name" => last_name
      } ->
        "#{first_name} #{last_name}"
      _ -> "#{user["user_name"]}"
    end
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
