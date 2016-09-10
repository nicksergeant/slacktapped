defmodule Slacktapped.Checkins do
  @instance_name System.get_env("INSTANCE_NAME") ||
    Application.get_env(:slacktapped, :instance_name)
  @redis Application.get_env(:slacktapped, :redis)

  @doc """
  Processes a checkin for use in a Slack post:

  1. Verifies the checkin is eligible to post.
  2. Parses the checkin to a Slack attachment.
  3. Adds the attachment to the checkin.
  4. Reports the checkin post to Redis.
  """
  def process_checkin(checkin) do
    with {:ok, checkin} <- is_eligible_checkin_post(checkin),
         {:ok, attachment} <- parse_checkin(checkin),
         {:ok, checkin} <- Slacktapped.Utils.add_attachments([attachment], checkin),
         {:ok, checkin} <- report_checkin_type({:ok, checkin}),
         do: {:ok, checkin}
  end

  @doc """
  Determines if a checkin is eligible to be posted to Slack.

  Checkin is ineligible to post if:

  1. There is a Redis key indicating that this checkin was posted under this
     instance, and had an image with it.
  2. There is a Redis key indicating that this checkin was posted under this
     instance, and had no image with it, but the checkin we see now still does
     not have an image.

  ## Examples

  A checkin that was not already posted:

      iex> Slacktapped.Checkins.is_eligible_checkin_post(%{"checkin_id" => 9985})
      {:ok, %{"checkin_id" => 9985}}

  A checkin that was already posted, and had an image:

      iex> Slacktapped.Checkins.is_eligible_checkin_post(%{"checkin_id" => 9988})
      {:error, %{"checkin_id" => 9988}}

  A checkin that was already posted and had no image, and we do not currently
  have an image:

      iex> Slacktapped.Checkins.is_eligible_checkin_post(%{"beer" => %{}, "checkin_id" => 5566})
      {:error, %{"beer" => %{}, "checkin_id" => 5566}}

  A checkin that was already posted and had no image, and we now have an
  image:

      iex> Slacktapped.Checkins.is_eligible_checkin_post(%{
      ...>   "beer" => %{},
      ...>   "checkin_id" => 5566,
      ...>   "media" => %{
      ...>     "items" => [
      ...>       %{
      ...>         "photo" => %{
      ...>           "photo_id" => 987,
      ...>           "photo_img_lg" => "http://path/to/beer/image"
      ...>         }
      ...>       }
      ...>     ]
      ...>   }
      ...> })
      {:ok, %{
        "beer" => %{},
        "checkin_id" => 5566,
        "media" => %{
          "items" => [
            %{
              "photo" => %{
                "photo_id" => 987,
                "photo_img_lg" => "http://path/to/beer/image"
              }
            }
          ]
        }
      }}

  """
  def is_eligible_checkin_post(checkin) do
    checkin_id = checkin["checkin_id"] || ""
    media_items = checkin["media"]["items"]
    has_image = is_list(media_items) and Enum.count(media_items) >= 1
    get_key = "GET #{@instance_name}:#{checkin_id}"

    cond do
      @redis.command("#{get_key}:with-image") == {:ok, "1"} ->
        {:error, checkin}
      @redis.command("#{get_key}:without-image") == {:ok, "1"} and not has_image ->
        {:error, checkin}
      true ->
        {:ok, checkin}
    end
  end

  @doc ~S"""
  Parses a checkin into an attachment for Slack.

  ## Examples

  A typical checkin with a rating and comment:

      iex> Slacktapped.Checkins.parse_checkin(%{
      ...>   "attachments" => [],
      ...>   "user" => %{
      ...>     "user_name" => "nicksergeant",
      ...>     "user_avatar" => "http://path/to/user/avatar"
      ...>   },
      ...>   "beer" => %{
      ...>     "bid" => 123,
      ...>     "beer_abv" => 4.5,
      ...>     "beer_label" => "http://path/to/beer/label",
      ...>     "beer_name" => "IPA",
      ...>     "beer_slug" => "two-lake-ipa",
      ...>     "beer_style" => "American IPA"
      ...>   },
      ...>   "brewery" => %{
      ...>     "brewery_id" => 1,
      ...>     "brewery_label" => "http://path/to/brewery/label",
      ...>     "brewery_name" => "Two Lake"
      ...>   },
      ...>   "checkin_comment" => "Lovely!",
      ...>   "checkin_id" => 567,
      ...>   "rating_score" => 3.5
      ...> })
      {:ok,
        %{
          "author_icon" => "http://path/to/user/avatar",
          "author_link" => "https://untappd.com/user/nicksergeant",
          "author_name" => "nicksergeant",
          "color" => "#FFCF0B",
          "fallback" => "Image of this checkin.",
          "footer" => "<https://untappd.com/brewery/1|Two Lake>",
          "footer_icon" => "http://path/to/brewery/label",
          "image_url" => "http://path/to/beer/label",
          "text" => "" <>
            "<https://untappd.com/user/nicksergeant|nicksergeant> is drinking " <>
            "<https://untappd.com/b/two-lake-ipa/123|IPA> " <>
            "(American IPA, 4.5% ABV)." <>
            "\nThey rated it a 3.5 and said \"Lovely!\"\n" <>
            "<https://untappd.com/user/nicksergeant/checkin/567|Toast »>",
          "title" => "IPA",
          "title_link" => "https://untappd.com/b/two-lake-ipa/123"
        }
      }

  A checkin without a rating:

      iex> Slacktapped.Checkins.parse_checkin(%{
      ...>   "attachments" => [],
      ...>   "checkin_comment" => "Lovely!"
      ...> })
      {:ok,
        %{
          "author_icon" => nil,
          "author_link" => "https://untappd.com/user/",
          "author_name" => nil,
          "color" => "#FFCF0B",
          "fallback" => "Image of this checkin.",
          "footer" => "<https://untappd.com/brewery/|>",
          "footer_icon" => nil,
          "image_url" => nil,
          "text" => "" <>
            "<https://untappd.com/user/|> is drinking " <>
            "<https://untappd.com/b//|> (, % ABV)." <>
            "\nThey said \"Lovely!\"\n" <>
            "<https://untappd.com/user//checkin/|Toast »>",
          "title" => nil,
          "title_link" => "https://untappd.com/b//"
        }
      }

  A checkin without a comment:

      iex> Slacktapped.Checkins.parse_checkin(%{"rating_score" => 1.5})
      {:ok,
        %{
          "author_icon" => nil,
          "author_link" => "https://untappd.com/user/",
          "author_name" => nil,
          "color" => "#FFCF0B",
          "fallback" => "Image of this checkin.",
          "footer" => "<https://untappd.com/brewery/|>",
          "footer_icon" => nil,
          "image_url" => nil,
          "text" => "" <>
            "<https://untappd.com/user/|> is drinking " <>
            "<https://untappd.com/b//|> (, % ABV)." <>
            "\nThey rated it a 1.5.\n" <>
            "<https://untappd.com/user//checkin/|Toast »>",
          "title" => nil,
          "title_link" => "https://untappd.com/b//"
        }
      }

  A checkin without a comment or rating:

      iex> Slacktapped.Checkins.parse_checkin(%{})
      {:ok,
        %{
          "author_icon" => nil,
          "author_link" => "https://untappd.com/user/",
          "author_name" => nil,
          "color" => "#FFCF0B",
          "fallback" => "Image of this checkin.",
          "footer" => "<https://untappd.com/brewery/|>",
          "footer_icon" => nil,
          "image_url" => nil,
          "text" => "" <>
            "<https://untappd.com/user/|> is drinking " <>
            "<https://untappd.com/b//|> (, % ABV).\n" <>
            "<https://untappd.com/user//checkin/|Toast »>",
          "title" => nil,
          "title_link" => "https://untappd.com/b//"
        }
      }

  A checkin with a rating of 0:

      iex> Slacktapped.Checkins.parse_checkin(%{"rating_score" => 0})
      {:ok,
        %{
          "author_icon" => nil,
          "author_link" => "https://untappd.com/user/",
          "author_name" => nil,
          "color" => "#FFCF0B",
          "fallback" => "Image of this checkin.",
          "footer" => "<https://untappd.com/brewery/|>",
          "footer_icon" => nil,
          "image_url" => nil,
          "text" => "" <>
            "<https://untappd.com/user/|> is drinking " <>
            "<https://untappd.com/b//|> (, % ABV).\n" <>
            "<https://untappd.com/user//checkin/|Toast »>",
          "title" => nil,
          "title_link" => "https://untappd.com/b//"
        }
      }

  A checkin with an image:

      iex> Slacktapped.Checkins.parse_checkin(%{
      ...>   "media" => %{
      ...>     "items" => [
      ...>       %{
      ...>         "photo" => %{
      ...>           "photo_id" => 987,
      ...>           "photo_img_lg" => "http://path/to/beer/image"
      ...>         }
      ...>       }
      ...>     ]
      ...>   }
      ...> })
      {:ok,
        %{
          "author_icon" => nil,
          "author_link" => "https://untappd.com/user/",
          "author_name" => nil,
          "color" => "#FFCF0B",
          "fallback" => "Image of this checkin.",
          "footer" => "<https://untappd.com/brewery/|>",
          "footer_icon" => nil,
          "image_url" => "http://path/to/beer/image",
          "text" => "" <>
            "<https://untappd.com/user/|> is drinking " <>
            "<https://untappd.com/b//|> (, % ABV).\n" <>
            "<https://untappd.com/user//checkin/|Toast »>",
          "title" => nil,
          "title_link" => "https://untappd.com/b//"
        }
      }

  A checkin with a venue:

      iex> Slacktapped.Checkins.parse_checkin(%{
      ...>   "attachments" => [],
      ...>   "venue" => %{
      ...>     "venue_id" => 789,
      ...>     "venue_name" => "Venue Name",
      ...>     "venue_slug" => "venue-slug"
      ...>   }
      ...> })
      {:ok,
        %{
          "author_icon" => nil,
          "author_link" => "https://untappd.com/user/",
          "author_name" => nil,
          "color" => "#FFCF0B",
          "fallback" => "Image of this checkin.",
          "footer" => "<https://untappd.com/brewery/|>",
          "footer_icon" => nil,
          "image_url" => nil,
          "text" => "" <>
            "<https://untappd.com/user/|> is drinking " <>
            "<https://untappd.com/b//|> (, % ABV) " <>
            "at <https://untappd.com/v/venue-slug/789|Venue Name>.\n" <>
            "<https://untappd.com/user//checkin/|Toast »>",
          "title" => nil,
          "title_link" => "https://untappd.com/b//"
        }
      }

  A checkin with an image, with a previously-posted checkin with no image:

      iex> Slacktapped.Checkins.parse_checkin(%{
      ...>   "checkin_id" => 5566,
      ...>   "media" => %{
      ...>     "items" => [
      ...>       %{
      ...>         "photo" => %{
      ...>           "photo_id" => 987,
      ...>           "photo_img_lg" => "http://path/to/beer/image"
      ...>         }
      ...>       }
      ...>     ]
      ...>   }
      ...> })
      {:ok,
        %{
          "author_icon" => nil,
          "author_link" => "https://untappd.com/user/",
          "author_name" => nil,
          "color" => "#FFCF0B",
          "fallback" => "Image of this checkin.",
          "footer" => "<https://untappd.com/brewery/|>",
          "footer_icon" => nil,
          "image_url" => "http://path/to/beer/image",
          "text" => "" <>
            "<https://untappd.com/user/|> added an image to " <>
            "<https://untappd.com/user//checkin/5566|their checkin> of " <>
            "<https://untappd.com/b//|>.",
          "title" => nil,
          "title_link" => "https://untappd.com/b//"
        }
      }

  The default Untappd beer label is ignored:

      iex> Slacktapped.Checkins.parse_checkin(%{
      ...>   "attachments" => [],
      ...>   "beer" => %{
      ...>     "beer_label" => "https://untappd.akamaized.net/site/assets/images/temp/badge-beer-default.png"
      ...>   }
      ...> })
      {:ok,
        %{
          "author_icon" => nil,
          "author_link" => "https://untappd.com/user/",
          "author_name" => nil,
          "color" => "#FFCF0B",
          "fallback" => "Image of this checkin.",
          "footer" => "<https://untappd.com/brewery/|>",
          "footer_icon" => nil,
          "image_url" => "",
          "text" => "" <>
            "<https://untappd.com/user/|> is drinking " <>
            "<https://untappd.com/b//|> (, % ABV).\n" <>
            "<https://untappd.com/user//checkin/|Toast »>",
          "title" => nil,
          "title_link" => "https://untappd.com/b//"
        }
      }

  """
  def parse_checkin(checkin) do
    c = Slacktapped.Utils.checkin_parts(checkin)

    rating_and_comment = cond do
      is_binary(c.checkin_comment)
        and c.checkin_comment != ""
        and is_number(c.checkin_rating) -> 
          "\nThey rated it a #{c.checkin_rating} and said \"#{c.checkin_comment}\""
      is_binary(c.checkin_comment)
        and c.checkin_comment != "" ->
          "\nThey said \"#{c.checkin_comment}\""
      is_number(c.checkin_rating) and c.checkin_rating > 0 ->
        "\nThey rated it a #{c.checkin_rating}."
      true -> ""
    end

    venue = if is_map(checkin["venue"]) do
      venue_id = checkin["venue"]["venue_id"]
      venue_name = checkin["venue"]["venue_name"]
      venue_slug = checkin["venue"]["venue_slug"]
      " at <https://untappd.com/v/#{venue_slug}/#{venue_id}|#{venue_name}>"
    end

    image_url = cond do
      is_list(c.media_items) and Enum.count(c.media_items) >= 1 ->
        c.media_items
          |> Enum.at(0)
          |> get_in(["photo", "photo_img_lg"])
      c.beer_label != "https://untappd.akamaized.net/site/assets/images/temp/badge-beer-default.png" ->
        c.beer_label
      true -> ""
    end

    # If we have an image and there was already a post for this checkin
    # *without* an image, only indicate that an image was added.
    cmd = "GET #{@instance_name}:#{c.checkin_id}:without-image"
    text = if is_binary(image_url) and
        @redis.command(cmd) == {:ok, "1"} do
      "#{c.user} added an image to <#{c.checkin_url}|their checkin> of #{c.beer}."
    else
      "#{c.user} is drinking #{c.beer} (#{c.beer_style}, #{c.beer_abv}% ABV)" <>
      "#{venue}.#{rating_and_comment}\n<#{c.checkin_url}|Toast »>"
    end

    {:ok, %{
      "author_icon" => c.user_avatar,
      "author_link" => c.user_url,
      "author_name" => c.user_username,
      "color" => "#FFCF0B",
      "fallback" => "Image of this checkin.",
      "footer" => c.brewery,
      "footer_icon" => c.brewery_label,
      "image_url" => image_url,
      "text" => text,
      "title" => c.beer_name,
      "title_link" => c.beer_url
    }}
  end

  @doc """
  Reports that a checkin was posted to Slack by setting a Redis key. There are
  two possible Redis keys indicating a post was made:

  1. <slacktapped-instance-name>:<checkin_id>:with-image
  2. <slacktapped-instance-name>:<checkin_id>:without-image

  Already-posted checkins that were previously posted without an image are
  posted again indicating that the user added an image to the checkin. If a
  record exists for the checkin with an image, the checkin is not posted again.

  ## Examples
  
      iex> Slacktapped.Checkins.report_checkin_type({:ok, %{}})
      {:ok, %{"reported_as" => "without-image"}}
  
      iex> Slacktapped.Checkins.report_checkin_type({:ok, %{
      ...>   "media" => %{
      ...>     "items" => [
      ...>       %{
      ...>         "photo" => %{
      ...>           "photo_id" => 987,
      ...>           "photo_img_lg" => "http://path/to/beer/image"
      ...>         }
      ...>       }
      ...>     ]
      ...>   }
      ...> }})
      {:ok, %{
        "reported_as" => "with-image",
        "media" => %{
          "items" => [
            %{
              "photo" => %{
                "photo_id" => 987,
                "photo_img_lg" => "http://path/to/beer/image"
              }
            }
          ]
        }
      }}

  """
  def report_checkin_type({:ok, checkin}) do
    checkin_id = checkin["checkin_id"]
    media_items = checkin["media"]["items"]
    has_image = is_list(media_items) and Enum.count(media_items) >= 1

    reported_as = cond do
      has_image == true ->
        @redis.command("SET #{@instance_name}:#{checkin_id}:with-image 1")
        "with-image"
      true ->
        @redis.command("SET #{@instance_name}:#{checkin_id}:without-image 1")
        "without-image"
    end

    checkin = Map.put(checkin, "reported_as", reported_as)

    {:ok, checkin}
  end
end
