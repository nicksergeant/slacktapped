defmodule Slacktapped do
  @slack Application.get_env(:slacktapped, :slack)
  @untappd Application.get_env(:slacktapped, :untappd)

  @doc """
  Fetches checkins from Untappd and then processes each checkin, its badges,
  and its comments.

  ## Example

     iex> Slacktapped.main
     :ok

  """
  def main do
    checkins
      # |> Enum.take(1) # TODO: Remove for prod.
      |> Enum.each(fn(checkin) ->
        with {:ok, checkin} <- process_checkin(checkin),
             {:ok, checkin} <- process_badges(checkin),
             {:ok, checkin} <- process_comments(checkin),
             do: :ok
      end)
  end

  @doc """
  Makes an API request to Untappd to fetch the recent checkins, then gets the
  body of the response. We then encode the response to a map and retrieve only
  the checkin items.
  """
  def checkins do
    @untappd.get("checkin/recent")
     |> Map.fetch!(:body)
     |> Poison.decode!
     |> get_in(["response", "checkins", "items"])
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
      ...>     "beer_abv" => 4.5,
      ...>     "beer_name" => "IPA",
      ...>     "beer_slug" => "two-lake-ipa",
      ...>     "beer_style" => "American IPA"
      ...>   },
      ...>   "brewery" => %{
      ...>     "brewery_id" => 1,
      ...>     "brewery_name" => "Two Lake"
      ...>   }
      ...> })
      {:ok,
        "<https://untappd.com/user/nicksergeant|nicksergeant> " <>
        "is drinking " <>
        "<https://untappd.com/b/two-lake-ipa/123|IPA> " <>
        "(American IPA, 4.5% ABV) " <>
        "by <https://untappd.com/brewery/1|Two Lake>."
      }

  A checkin without a rating:

  A checkin with an image:

  An existing checkin with a new image:

  """
  def parse_checkin(checkin) do
    {:ok, user_name} = parse_name(checkin["user"])

    beer_abv = checkin["beer"]["beer_abv"]
    beer_id = checkin["beer"]["bid"]
    beer_name = checkin["beer"]["beer_name"]
    beer_slug = checkin["beer"]["beer_slug"]
    beer_style = checkin["beer"]["beer_style"]
    brewery_id = checkin["brewery"]["brewery_id"]
    brewery_name = checkin["brewery"]["brewery_name"]
    user_username = checkin["user"]["user_name"]

    beer = "<https://untappd.com/b/#{beer_slug}/#{beer_id}|#{beer_name}>"
    brewery = "<https://untappd.com/brewery/#{brewery_id}|#{brewery_name}>"
    user = "<https://untappd.com/user/#{user_username}|#{user_name}>"

    # TODO: user rating and checkin_comment.

    {:ok,
      "#{user} is drinking #{beer} (#{beer_style}, #{beer_abv}% ABV) " <>
      "by #{brewery}."}
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

  def process_badge(badge) do
    parse_badge(badge)
      |> @slack.post
    {:ok, badge}
  end

  def process_badges(checkin) do
    get_in(checkin, ["badges", "items"])
      |> Enum.each(&(process_badge(&1)))
    {:ok, checkin}
  end

  @doc ~S"""
  Parses a checkin and posts it to Slack, if the checkin is eligible.

  Ineligible checkins contain the text "#shh" in the checkin comment. For, you
  know, day drinking.

  ## Examples

  A normal checkin gets through:

      iex> Slacktapped.process_checkin(%{})
      {:ok, %{}}

  Checkins with the text "#shh" in the checkin comment are ignored:

      iex> Slacktapped.process_checkin(%{"checkin_comment" => "#shh"})
      {:error, %{"checkin_comment" => "#shh"}}

  """
  def process_checkin(checkin) do
    with {:ok, checkin} <- is_eligible_checkin(checkin),
         {:ok, message} <- parse_checkin(checkin),
         {:ok, message} <- @slack.post(message),
         do: {:ok, checkin}
  end

  def process_comment(comment) do
    parse_comment(comment)
      |> @slack.post
    {:ok, comment}
  end

  def process_comments(checkin) do
    get_in(checkin, ["comments", "items"])
      |> Enum.each(&(process_comment(&1)))
    {:ok, checkin}
  end

end
