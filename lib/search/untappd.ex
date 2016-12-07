defmodule Slacktapped.Search.Untappd do
  @beersearch Application.get_env(:slacktapped, :beersearch)
  @untappd_slash_cmd_token System.get_env("UNTAPPD_SLASH_CMD_TOKEN") ||
    Application.get_env(:slacktapped, :untappd_slash_cmd_token)

  @doc ~S"""
  Handles a Slack slash-command search for a beer on Untappd.

  ## Examples

  Request with a good token:

      iex> Slacktapped.Search.Untappd.handle_search(%{
      ...>   "channel_id" => "C2147483705",
      ...>   "channel_name" => "test",
      ...>   "command" => "/untappd",
      ...>   "response_url" => "https://hooks.slack.com/commands/1234/5678",
      ...>   "team_domain" => "example",
      ...>   "team_id" => "T0001",
      ...>   "text" => "dogfish 60",
      ...>   "token" => "abc123",
      ...>   "user_id" => "U2147483697",
      ...>   "user_name" => "Steve"
      ...> })
      {:ok,
        %{
          "attachments" => [
            %{
              "color" => "#FFCF0B",
              "footer" => "<http://path/to/brewery|Dogfish Head Craft Brewery>",
              "image_url" => "https://untappd.akamaized.net/site/beer_logos/beer-3952_a5c9d_sm.jpeg",
              "text" => "IPA - American, 6% ABV\nAverage rating: 3.898",
              "title" => "60 Minute IPA",
              "title_link" => "https://untappd.com/b/dogfish-head-craft-brewery-60-minute-ipa/3952"
            }
          ],
          "icon_url" => "https://slacktapped.s3.amazonaws.com/icon.jpg",
          "response_type" => "ephemeral",
          "username" => "Untappd"
        }
      }

  Bad tokens are dropped:

      iex> Slacktapped.Search.Untappd.handle_search(%{"token" => "nope"})
      {:error, %{}}

  No results:

      iex> Slacktapped.Search.Untappd.handle_search(%{"token" => "abc123", "text" => "fdsafdsa"})
      {:ok,
        %{
          "attachments" => [
            %{
              "color" => "#FFCF0B",
              "text" => "No results."
            }
          ],
          "icon_url" => "https://slacktapped.s3.amazonaws.com/icon.jpg",
          "response_type" => "ephemeral",
          "username" => "Untappd"
        }
      }

  Respond to channel publicly:

      iex> Slacktapped.Search.Untappd.handle_search(%{
      ...>   "token" => "abc123",
      ...>   "text" => "fdsafdsa -public"
      ...> })
      {:ok,
        %{
          "attachments" => [
            %{
              "color" => "#FFCF0B",
              "text" => "No results."
            }
          ],
          "icon_url" => "https://slacktapped.s3.amazonaws.com/icon.jpg",
          "response_type" => "in_channel",
          "username" => "Untappd"
        }
      }

  """
  def handle_search(params) do
    token = params["token"]

    cond do
      token != @untappd_slash_cmd_token ->
        {:error, %{}}
      token == @untappd_slash_cmd_token ->
        respond_publicly = Regex.match?(~r/-public/, params["text"])
        text = String.trim(Regex.replace(~r/-public/, params["text"], ""))
        respond(@beersearch.search(text), respond_publicly)
    end
  end

  defp respond([], respond_publicly) do
    {:ok, %{
      "icon_url" => "https://slacktapped.s3.amazonaws.com/icon.jpg",
      "username" => "Untappd",
      "response_type" => if respond_publicly do "in_channel" else "ephemeral" end,
      "attachments" => [
        %{
          "color" => "#FFCF0B",
          "text" => "No results."
        }
      ]
    }}
  end

  defp respond(results, respond_publicly) do
    result = Enum.at(results, 0)

    {:ok, %{
      "icon_url" => "https://slacktapped.s3.amazonaws.com/icon.jpg",
      "username" => "Untappd",
      "response_type" => if respond_publicly do "in_channel" else "ephemeral" end,
      "attachments" => [
        %{
          "color" => "#FFCF0B",
          "footer" => "<#{result.brewery_url}|#{result.brewery}>",
          "image_url" => result.image,
          "text" => "#{result.style}, #{result.abv}\nAverage rating: #{result.rating}",
          "title" => result.name,
          "title_link" => result.url
        }
      ]
    }}
  end
end
