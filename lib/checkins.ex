defmodule Slacktapped.Checkins do
  @doc """
  Parses a checkin into an attachment for Slack.
  """
  def process_checkin(checkin) do
    Slacktapped.Checkins.parse_checkin(checkin)
      |> Slacktapped.add_attachment(checkin)
  end

  @doc ~S"""
  Parses a checkin into an attachment for Slack.

  ## Examples

  A typical checkin with a rating and comment:

      iex> Slacktapped.Checkins.parse_checkin(%{
      ...>   "attachments" => [],
      ...>   "user" => %{
      ...>     "user_name" => "nicksergeant"
      ...>   },
      ...>   "beer" => %{
      ...>     "bid" => 123,
      ...>     "beer_abv" => 4.5,
      ...>     "beer_label" => "https://foo.bar/site/beer_logos/label.jpeg",
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
      {:ok, %{
        "image_url" => "https://foo.bar/site/beer_logos/label.jpeg",
        "pretext" => "" <>
          "<https://untappd.com/user/nicksergeant|nicksergeant> is drinking " <>
          "<https://untappd.com/b/two-lake-ipa/123|IPA>." <>
          "\nThey rated it a 3.5 and said \"Lovely!\" " <>
          "<https://untappd.com/user/nicksergeant/checkin/567|Toast »>"
        }
      }

  A checkin without a rating:

      iex> Slacktapped.Checkins.parse_checkin(%{
      ...>   "attachments" => [],
      ...>   "checkin_comment" => "Lovely!"
      ...> })
      {:ok, %{
        "image_url" => nil,
        "pretext" => "" <>
          "<https://untappd.com/user/|> is drinking " <>
          "<https://untappd.com/b//|>." <>
          "\nThey said \"Lovely!\" " <>
          "<https://untappd.com/user//checkin/|Toast »>"
        }
      }

  A checkin without a comment:

      iex> Slacktapped.Checkins.parse_checkin(%{"rating_score" => 1.5})
      {:ok, %{
        "image_url" => nil,
        "pretext" => "" <>
          "<https://untappd.com/user/|> is drinking " <>
          "<https://untappd.com/b//|>." <>
          "\nThey rated it a 1.5. " <>
          "<https://untappd.com/user//checkin/|Toast »>"
        }
      }

  A checkin without a comment or rating:

      iex> Slacktapped.Checkins.parse_checkin(%{})
      {:ok, %{
        "image_url" => nil,
        "pretext" => "" <>
          "<https://untappd.com/user/|> is drinking " <>
          "<https://untappd.com/b//|>. " <>
          "<https://untappd.com/user//checkin/|Toast »>"
        }
      }

  A checkin with an image:

      iex> Slacktapped.Checkins.parse_checkin(%{
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
      {:ok, %{
        "image_url" => "https://path/to/image",
        "pretext" => "" <>
          "<https://untappd.com/user/|> is drinking " <>
          "<https://untappd.com/b//|>. " <>
          "<https://untappd.com/user//checkin/|Toast »>"
        }
      }

  A checkin with a venue:

  ## Sample:

  {
    "attachments": [
      {
          "fallback": "Image of this checkin.",
          "color": "#FFCF0B",
          "pretext": "<http://google.com/to/user|Nick Sergeant> is drinking <http://google.com/path/to/beer|Kirby's Kolsch> at <http://google.com/to/venue|Sampson State Park>.\nThey rated it a 3.5 and said \"Lovely!\" <http://google.com/to/toast|Toast »>",
          "author_name": "Muskoka Brewery",
          "author_link": "http://google.com/path/to/brewery",
          "author_icon": "https://untappd.akamaized.net/site/brewery_logos/brewery-muskoka.jpg",
          "title": "Kirby's Kolsch",
          "title_link": "http://google.com/path/to/beer",
          "text": "Kolsch, 4.6% ABV",
          "footer": "<http://google.com/to/user|nicksergeant>",
          "footer_icon": "https://gravatar.com/avatar/a74159ce0c29f89b75a25037e40b27a4?size=100&d=https%3A%2F%2Funtappd.akamaized.net%2Fsite%2Fassets%2Fimages%2Fdefault_avatar_v2.jpg%3Fv%3D1"
      }
    ]
  }

  """
  def parse_checkin(checkin) do
    {:ok, user_name} = Slacktapped.parse_name(checkin["user"])

    beer_abv = checkin["beer"]["beer_abv"]
    beer_id = checkin["beer"]["bid"]
    beer_label = checkin["beer"]["beer_label"]
    beer_name = checkin["beer"]["beer_name"]
    beer_slug = checkin["beer"]["beer_slug"]
    beer_style = checkin["beer"]["beer_style"]
    brewery_id = checkin["brewery"]["brewery_id"]
    brewery_name = checkin["brewery"]["brewery_name"]
    checkin_comment = checkin["checkin_comment"]
    checkin_id = checkin["checkin_id"]
    checkin_rating = checkin["rating_score"]
    media_items = checkin["media"]["items"]
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

    image_url = cond do
      is_list(media_items) and Enum.count(media_items) >= 1 ->
        media_items
          |> Enum.at(0)
          |> get_in(["photo", "photo_img_lg"])
      true -> beer_label
    end

    pretext = "#{user} is drinking #{beer}.#{rating_and_comment} #{toast}"

    {:ok, %{
      "image_url" => image_url,
      "pretext" => pretext
    }}
  end
end
