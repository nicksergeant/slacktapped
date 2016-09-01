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
      |> Enum.take(1) # TODO: Remove for prod.
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

  A typical checkin with a rating and comment:

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
      ...>   },
      ...>   "checkin_comment" => "Lovely!",
      ...>   "checkin_id" => 567,
      ...>   "rating_score" => 3.5
      ...> })
      {:ok,
        "<https://untappd.com/user/nicksergeant|nicksergeant> is drinking " <>
        "<https://untappd.com/b/two-lake-ipa/123|IPA> " <>
        "(American IPA, 4.5% ABV) " <>
        "by <https://untappd.com/brewery/1|Two Lake>.\n" <>
        "They rated it a 3.5 and said \"Lovely!\" " <>
        "<https://untappd.com/user/nicksergeant/checkin/567|Toast »>",
       ""}

  A checkin without a rating:

      iex> Slacktapped.parse_checkin(%{"checkin_comment" => "Lovely!"})
      {:ok,
        "<https://untappd.com/user/|> is drinking " <>
        "<https://untappd.com/b//|> (, % ABV) by " <>
        "<https://untappd.com/brewery/|>.\nThey said \"Lovely!\" " <>
        "<https://untappd.com/user//checkin/|Toast »>",
       ""}

  A checkin without a comment:

      iex> Slacktapped.parse_checkin(%{"rating_score" => 1.5})
      {:ok,
        "<https://untappd.com/user/|> is drinking " <>
        "<https://untappd.com/b//|> (, % ABV) by " <>
        "<https://untappd.com/brewery/|>.\nThey rated it a 1.5. " <>
        "<https://untappd.com/user//checkin/|Toast »>",
       ""}

  A checkin without a comment or rating:

      iex> Slacktapped.parse_checkin(%{})
      {:ok,
        "<https://untappd.com/user/|> is drinking " <>
        "<https://untappd.com/b//|> (, % ABV) by " <>
        "<https://untappd.com/brewery/|>. " <>
        "<https://untappd.com/user//checkin/|Toast »>",
       ""}

  A checkin with an image:

      iex> Slacktapped.parse_checkin(%{
      ...>   "media" => %{
      ...>     "items" => [
      ...>       %{
      ...>         "photo" => %{
      ...>           "photo_id" => 987,
      ...>           "photo_img_lg" => "https://path/to/image"
      ...>         }
      ...>       }
      ...>     ]
      ...>   }
      ...> })
      {:ok,
        "<https://untappd.com/user/|> is drinking " <>
        "<https://untappd.com/b//|> (, % ABV) by " <>
        "<https://untappd.com/brewery/|>. " <>
        "<https://untappd.com/user//checkin/|Toast »>",
       "https://path/to/image"}

  An existing checkin with a new image:

  ### TODO:

  {
    "attachments": [
        {
            "fallback": "Image of this checkin.",
            "color": "#FFCF0B",
            "pretext": "<http://google.com/to/user|Nick Sergeant> is drinking Kirby's Kolsch.\nThey rated it a 3.5 and said \"Lovely!\" <http://google.com/to/toast|Toast »>",
            "author_name": "Muskoka Brewery",
            "author_link": "http://google.com/path/to/brewery",
            "author_icon": "https://untappd.akamaized.net/site/brewery_logos/brewery-muskoka.jpg",
            "title": "Kirby's Kolsch",
            "title_link": "http://google.com/path/to/beer",
            "text": "Kolsch, 4.6% ABV",
            "image_url": "https://untappd.akamaized.net/photo/2016_08_28/7d8e03ffe8f258f9db445e17894c2c12_640x640.jpg"
        }
    ]
  }

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
    checkin_comment = checkin["checkin_comment"]
    checkin_id = checkin["checkin_id"]
    checkin_rating = checkin["rating_score"]
    user_username = checkin["user"]["user_name"]

    beer = "<https://untappd.com/b/#{beer_slug}/#{beer_id}|#{beer_name}>"
    brewery = "<https://untappd.com/brewery/#{brewery_id}|#{brewery_name}>"
    toast = "<https://untappd.com/user/#{user_username}/checkin/#{checkin_id}|Toast »>"
    user = "<https://untappd.com/user/#{user_username}|#{user_name}>"

    rating_and_comment = cond do
      is_binary(checkin_comment)
        and checkin_comment != ""
        and is_number(checkin_rating) -> 
          "\nThey rated it a #{checkin_rating} and said \"#{checkin_comment}\""
      is_binary(checkin_comment)
        and checkin_comment != "" ->
          "\nThey said \"#{checkin_comment}\""
      is_number(checkin_rating) ->
        "\nThey rated it a #{checkin_rating}."
      true -> ""
    end

    media_items = checkin["media"]["items"]

    image_url = cond do
      is_list(media_items) and Enum.count(media_items) >= 1 ->
        media_items
          |> Enum.at(0)
          |> get_in(["photo", "photo_img_lg"])
      true -> ""
    end

    {:ok,
      "#{user} is drinking #{beer} (#{beer_style}, #{beer_abv}% ABV) " <>
      "by #{brewery}.#{rating_and_comment} #{toast}",
     image_url}
  end

  def parse_comment(comment) do
    "comment"
  end

  @doc """
  Returns the user's name. If both first and last name are present, returns
  "First-name Last-name", otherwise returns "username".

  ## Examples

      iex> Slacktapped.parse_name(%{"user_name" => "nicksergeant"})
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
  Parses a badge and posts it to Slack.

  ## Example
  
      iex> Slacktapped.process_badge(%{})
      {:ok, %{}}

  """
  def process_badge(badge) do
    parse_badge(badge)
      |> @slack.post
    {:ok, badge}
  end

  @doc """
  Gets all of the badges from a checkin and processes them.
  """
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
         {:ok, message, image_url} <- parse_checkin(checkin),
         {:ok, _message} <- @slack.post(message, image_url),
         do: {:ok, checkin}
  end

  @doc """
  Parses a comment and posts it to Slack.

  ## Example
  
      iex> Slacktapped.process_comment(%{})
      {:ok, %{}}

  """
  def process_comment(comment) do
    parse_comment(comment)
      |> @slack.post
    {:ok, comment}
  end

  @doc """
  Gets all of the comments from a checkin and processes them.
  """
  def process_comments(checkin) do
    get_in(checkin, ["comments", "items"])
      |> Enum.each(&(process_comment(&1)))
    {:ok, checkin}
  end

end
