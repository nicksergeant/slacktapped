defmodule Slacktapped do
  @slack Application.get_env(:slacktapped, :slack)
  @untappd Application.get_env(:slacktapped, :untappd)

  def main do
    checkins
      |> Enum.each(fn(checkin) ->
        checkin
          |> process_checkin
          |> process_badges
          |> process_comments
      end)
  end

  def checkins do
    @untappd.get("checkin/recent")
     |> Map.fetch!(:body)
     |> Poison.decode!
     |> get_in(["response", "checkins", "items"])
  end

  def parse_badge(badge) do
    "badge"
  end

  @doc ~S"""
  Parses a checkin to a string for Slack.

  ## Examples

  A normal checkin:

      iex> Slacktapped.parse_checkin(%{
      ...>   "user" => %{
      ...>     "user_name" => "nicksergeant"
      ...>   },
      ...>   "beer" => %{
      ...>     "bid" => 123,
      ...>     "beer_name" => "IPA",
      ...>     "beer_slug" => "two-lake-ipa"
      ...>   }
      ...> })
      {:ok,
        "<a href=\"https://untappd.com/user/nicksergeant\">nicksergeant</a> " <>
        "is drinking " <>
        "<a href=\"https://untappd.com/b/two-lake-ipa/123\">IPA</a>"}

  A checkin without a rating:

  A checkin with an image:

  An existing checkin with a new image:

  """
  def parse_checkin(checkin) do
    {:ok, user_name} = parse_name(checkin["user"])
    user_username = checkin["user"]["user_name"]
    user = "<a href=\"https://untappd.com/user/#{user_username}\">" <>
      "#{user_name}</a>"

    beer_id = checkin["beer"]["bid"]
    beer_name = checkin["beer"]["beer_name"]
    beer_slug = checkin["beer"]["beer_slug"]
    beer = "<a href=\"https://untappd.com/b/#{beer_slug}/#{beer_id}\">" <>
      "#{beer_name}</a>"

    # """
    #   #{username} is drinking #{beer_name} (#{beer_type}, #{abv} ABV)
    #   by #{brewery}. They rated it a #{rating} and said \"#{comment}\".
    # """
    {:ok, "#{user} is drinking #{beer}"}
  end

  def parse_comment(comment) do
    "comment"
  end

  @doc """
  Returns the user's name. If both first and last name are present, returns
  "First-name Last-name", otherwise returns "username".

  ## Examples

      iex> Slacktapped.parse_name(%{
      ...>   "user_name" => "nicksergeant"
      ...> })
      {:ok, "nicksergeant"}

      iex> Slacktapped.parse_name(%{
      ...>   "user_name" => "nicksergeant",
      ...>   "first_name" => "Nick",
      ...>   "last_name" => "Sergeant"
      ...> })
      {:ok, "Nick Sergeant"}

      iex> Slacktapped.parse_name(%{
      ...>   "user_name" => "nicksergeant",
      ...>   "first_name" => "Nick"
      ...> })
      {:ok, "nicksergeant"}

  """
  def parse_name(user) do
    case user do
      %{
        "first_name" => first_name,
        "last_name" => last_name
      } ->
        {:ok, "#{first_name} #{last_name}"}
      _ ->
        {:ok, "#{user["user_name"]}"}
    end
  end

  @doc """
  Determines if a checkin is eligible to be posted to Slack. Checkin is
  ineligible if the checkin_comment contains the text "#shh".

  ## Examples

      iex> Slacktapped.is_eligible_checkin(%{})
      {:ok, %{}}

      iex> Slacktapped.is_eligible_checkin(%{"checkin_comment" => "#shh"})
      {:error, %{"checkin_comment" => "#shh"}}

  """
  def is_eligible_checkin(checkin) do
    cond do
      is_nil(checkin["checkin_comment"]) ->
        {:ok, checkin}
      String.match?(checkin["checkin_comment"], ~r/#shh/) ->
        {:error, checkin}
      true ->
        {:ok, checkin}
    end
  end

  def process_badge(badge) do
    parse_badge(badge) |> @slack.post
    {:ok, badge}
  end

  @doc ~S"""
  Parses a checkin and posts it to Slack, if the checkin is eligible.

  Ineligible checkins contain the text "#shh" in the checkin comment. For, you
  know, day drinking.

  ## Examples:

  A normal checkin gets through:

      iex> Slacktapped.process_checkin(%{})
      {:ok,
        "<a href=\"https://untappd.com/user/\"></a> is drinking " <>
        "<a href=\"https://untappd.com/b//\"></a>"}

  Checkins with the text "#shh" in the checkin comment are ignored:

      iex> Slacktapped.process_checkin(%{"checkin_comment" => "#shh"})
      {:error, %{"checkin_comment" => "#shh"}}

  """
  def process_checkin(checkin) do
    with {:ok, checkin} <- is_eligible_checkin(checkin),
         {:ok, checkin} <- parse_checkin(checkin),
         do: @slack.post(checkin)
  end

  def process_comment(comment) do
    parse_comment(comment) |> @slack.post
    {:ok, comment}
  end

  def process_badges({:ok, checkin}) do
    get_in(checkin, ["badges", "items"])
      |> Enum.each(&(process_badge(&1)))
    {:ok, checkin}
  end

  def process_comments({:ok, checkin}) do
    get_in(checkin, ["comments", "items"])
      |> Enum.each(&(process_comment(&1)))
    {:ok, checkin}
  end
end
