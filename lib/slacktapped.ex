defmodule Slacktapped do
  import Supervisor.Spec
  require Logger
  use Application

  @instance_name System.get_env("INSTANCE_NAME") ||
    Application.get_env(:slacktapped, :instance_name)
  @redis Application.get_env(:slacktapped, :redis)
  @slack Application.get_env(:slacktapped, :slack)
  @untappd Application.get_env(:slacktapped, :untappd)

  def start(_type, _args) do
    cowboy_port = Application.get_env(:slacktapped, :cowboy_port, 8000)
    redis_host = Application.get_env(:slacktapped, :redis_host, "localhost")
    redis_port = Application.get_env(:slacktapped, :redis_port, 6379)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Slacktapped.Router, [], port: cowboy_port),
      worker(Redix, [
        [
          host: redis_host,
          port: redis_port
        ],
        [name: :redix]
      ])
    ]

    Logger.info("[Server] Started")

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @doc """
  Fetches checkins from Untappd and then processes each checkin.

  ## Example

     iex> Slacktapped.main
     :ok

  """
  def main do
    Logger.info("[Processor] Running...")
    @untappd.get("checkin/recent")
      |> Map.fetch!(:body)
      |> Poison.decode!
      |> get_in(["response", "checkins", "items"])
      |> Enum.map(&(handle_checkin(&1)))
      |> Enum.reduce([], fn({_ok, checkin}, acc) ->
          acc ++ checkin["attachments"]
        end)
      |> @slack.post
    Logger.info("[Processor] Done.")
  end

  @doc ~S"""
  Processes a checkin and posts it to Slack, if the checkin is eligible. It
  adds an "attachments" list to the checkin map, which is used to aggregate
  individual attachments from the checkin, comments, and badges. The final
  state of "attachments" is what gets sent directly to the Slack webhook.

  Ineligible checkins contain the text "#shh" in the checkin comment.
  For, you know, day drinking.

  ## Examples

  A normal checkin gets through:

      iex> Slacktapped.handle_checkin(%{"beer" => %{}})
      {:ok,
        %{
          "beer" => %{},
          "reported_as" => "without-image",
          "attachments" => [
            %{
              "author_icon" => nil,
              "author_link" => "https://untappd.com/user/",
              "author_name" => nil,
              "color" => "#FFCF0B",
              "fallback" => "Image of this checkin.",
              "footer" => "<https://untappd.com/brewery/|>",
              "footer_icon" => nil,
              "image_url" => nil,
              "text" => "<https://untappd.com/user/|> is drinking " <>
                "<https://untappd.com/b//|> (, % ABV).\n" <>
                "<https://untappd.com/user//checkin/|Toast »>",
              "title" => nil,
              "title_link" => "https://untappd.com/b//"
            }
          ]
        }
      }

  A checkin with no beer is ignored:

      iex> Slacktapped.handle_checkin(%{})
      {:error, %{"attachments" => []}}

  Checkins with the text "#shh" in the checkin comment are ignored:

      iex> Slacktapped.handle_checkin(%{"checkin_comment" => "#shh"})
      {:error, %{"attachments" => [], "checkin_comment" => "#shh"}}

  """
  def handle_checkin(checkin) do
    checkin = Map.put(checkin, "attachments", [])

    with {:ok, checkin} <- is_eligible_checkin(checkin),
         {_ok, checkin} <- Slacktapped.Checkins.process_checkin(checkin),
         {_ok, checkin} <- Slacktapped.Badges.process_badges(checkin),
         # {:ok, checkin} <- Slacktapped.Checkins.process_comments(checkin),
         do: {:ok, checkin}
  end

  @doc """
  Determines if a checkin is eligible to be processed.

  Checkin is ineligible if:
  
  1. The checkin_comment contains the text "#shh".
  2. There is no beer (sad).

  ## Examples

      iex> Slacktapped.is_eligible_checkin(%{})
      {:error, %{}}

      iex> Slacktapped.is_eligible_checkin(%{"beer" => %{}})
      {:ok, %{"beer" => %{}}}

      iex> Slacktapped.is_eligible_checkin(%{"checkin_comment" => "#shh"})
      {:error, %{"checkin_comment" => "#shh"}}

  """
  def is_eligible_checkin(checkin) do
    checkin_comment = checkin["checkin_comment"] || ""

    cond do
      String.match?(checkin_comment, ~r/#shh/) ->
        {:error, checkin}
      is_nil(checkin["beer"]) ->
        {:error, checkin}
      true ->
        {:ok, checkin}
    end
  end

  @doc """
  Adds an attachment to the checkin's attachments list.

  ## Example

      iex> Slacktapped.add_attachments([%{"foo" => "bar"}], %{"attachments" => []})
      {:ok, %{"attachments" => [%{"foo" => "bar"}]}}

      iex> Slacktapped.add_attachments([%{"foo" => "bar"}, %{"wat" => "ba"}], %{"attachments" => []})
      {:ok, %{"attachments" => [%{"foo" => "bar"}, %{"wat" => "ba"}]}}

  """
  def add_attachments(attachments, checkin) do
    new_attachments = checkin["attachments"] ++ attachments
    checkin = Map.put(checkin, "attachments", new_attachments)
    {:ok, checkin}
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
end
