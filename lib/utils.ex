defmodule Slacktapped.Utils do
  @doc """
  Adds attachments to the checkins attachments list.

  ## Example

      iex> Slacktapped.Utils.add_attachments([%{"foo" => "bar"}], %{"attachments" => []})
      {:ok, %{"attachments" => [%{"foo" => "bar"}]}}

      iex> Slacktapped.Utils.add_attachments([%{"foo" => "bar"}, %{"wat" => "ba"}], %{"attachments" => []})
      {:ok, %{"attachments" => [%{"foo" => "bar"}, %{"wat" => "ba"}]}}

  """
  def add_attachments(attachments, checkin) do
    {:ok, Map.put(
      checkin,
      "attachments",
      checkin["attachments"] ++ attachments
    )}
  end

  @doc """
  Returns a map of most-used checkin parts for convenience.

  ## Example

      iex> Slacktapped.Utils.checkin_parts(%{
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
      %{
        beer: "<https://untappd.com/b/two-lake-ipa/123|IPA>",
        beer_abv: 4.5,
        beer_id: 123,
        beer_label: "http://path/to/beer/label",
        beer_name: "IPA",
        beer_slug: "two-lake-ipa",
        beer_style: "American IPA",
        beer_url: "https://untappd.com/b/two-lake-ipa/123",
        brewery: "<https://untappd.com/brewery/1|Two Lake>",
        brewery_id: 1,
        brewery_label: "http://path/to/brewery/label",
        brewery_name: "Two Lake",
        brewery_url: "https://untappd.com/brewery/1",
        checkin_comment: "Lovely!",
        checkin_id: 567,
        checkin_rating: 3.5,
        checkin_url: "https://untappd.com/user/nicksergeant/checkin/567",
        media_items: nil,
        user: "<https://untappd.com/user/nicksergeant|nicksergeant>",
        user_avatar: "http://path/to/user/avatar",
        user_name: "nicksergeant",
        user_url: "https://untappd.com/user/nicksergeant",
        user_username: "nicksergeant"
      }

  """
  def checkin_parts(checkin) do
    c = %{
      beer_abv: checkin["beer"]["beer_abv"],
      beer_id: checkin["beer"]["bid"],
      beer_label: checkin["beer"]["beer_label"],
      beer_name: checkin["beer"]["beer_name"],
      beer_slug: checkin["beer"]["beer_slug"],
      beer_style: checkin["beer"]["beer_style"],
      brewery_id: checkin["brewery"]["brewery_id"],
      brewery_label: checkin["brewery"]["brewery_label"],
      brewery_name: checkin["brewery"]["brewery_name"],
      checkin_comment: checkin["checkin_comment"],
      checkin_id: checkin["checkin_id"],
      checkin_rating: checkin["rating_score"],
      media_items: checkin["media"]["items"],
      user_avatar: checkin["user"]["user_avatar"],
      user_username: checkin["user"]["user_name"],
      user_name: parse_name(checkin["user"])
    }

    c = Map.merge(c, %{
      beer_url: "https://untappd.com/b/#{c.beer_slug}/#{c.beer_id}",
      brewery_url: "https://untappd.com/brewery/#{c.brewery_id}",
      checkin_url: "https://untappd.com/user/#{c.user_username}/checkin/" <>
        "#{c.checkin_id}",
      user_url: "https://untappd.com/user/#{c.user_username}"
    })

    c = Map.merge(c, %{
      beer: "<#{c.beer_url}|#{c.beer_name}>",
      brewery: "<#{c.brewery_url}|#{c.brewery_name}>",
      user: "<#{c.user_url}|#{c.user_name}>"
    })

    c
  end

  @doc """
  Returns the user's name. If both first and last name are present, returns
  "First-name Last-name", otherwise returns "username".

  ## Examples

      iex> Slacktapped.Utils.parse_name(%{"user_name" => "nicksergeant"})
      "nicksergeant"

      iex> Slacktapped.Utils.parse_name(%{
      ...>   "user_name" => "nicksergeant",
      ...>   "first_name" => "Nick",
      ...>   "last_name" => "Sergeant"
      ...> })
      "Nick Sergeant"

      iex> Slacktapped.Utils.parse_name(%{
      ...>   "user_name" => "nicksergeant",
      ...>   "first_name" => "Nick"
      ...> })
      "nicksergeant"

  """
  def parse_name(user) do
    case user do
      %{
        "first_name" => first_name,
        "last_name" => last_name
      } ->
        "#{first_name} #{last_name}"
      _ ->
        "#{user["user_name"]}"
    end
  end
end
