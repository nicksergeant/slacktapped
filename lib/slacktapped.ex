defmodule Slacktapped do
  import Supervisor.Spec
  require Logger
  use Application

  @instance_name Application.get_env(:slacktapped, :instance_name)
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
      |> Enum.take(1) # TODO: Remove for prod.
      |> Enum.map(&(handle_checkin(&1)))
      |> Enum.reduce([], fn({:ok, checkin}, acc) ->
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
                "<https://untappd.com/b//|> (, % ABV). " <>
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
         {:ok, checkin} <- Slacktapped.Checkins.process_checkin(checkin),
         # {:ok, checkin} <- Slacktapped.Checkins.process_badges(checkin),
         # {:ok, checkin} <- Slacktapped.Checkins.process_comments(checkin),
         do: {:ok, checkin}
  end

  @doc """
  Determines if a checkin is eligible to be posted to Slack.

  Checkin is ineligible if:
  
  1. The checkin_comment contains the text "#shh".
  2. There is no beer (sad).
  3. There is a Redis key indicating that this checkin was posted under this
     instance, and had an image with it.
  4. There is a Redis key indicating that this checkin was posted under this
     instance, and had no image with it, but the checkin we see now still does
     not have an image.

  ## Examples

      iex> Slacktapped.is_eligible_checkin(%{})
      {:error, %{}}

      iex> Slacktapped.is_eligible_checkin(%{"beer" => %{}})
      {:ok, %{"beer" => %{}}}

      iex> Slacktapped.is_eligible_checkin(%{"checkin_comment" => "#shh"})
      {:error, %{"checkin_comment" => "#shh"}}

  A checkin that was already posted, and had an image:

      iex> Slacktapped.is_eligible_checkin(%{"checkin_id" => 9988})
      {:error, %{"checkin_id" => 9988}}

  A checkin that was already posted and had no image, and we do not currently
  have an image:

      iex> Slacktapped.is_eligible_checkin(%{"beer" => %{}, "checkin_id" => 5566})
      {:error, %{"beer" => %{}, "checkin_id" => 5566}}

  A checkin that was already posted and had no image, and we now have an
  image:

      iex> Slacktapped.is_eligible_checkin(%{
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
  def is_eligible_checkin(checkin) do
    checkin_id = checkin["checkin_id"] || ""
    checkin_comment = checkin["checkin_comment"] || ""
    media_items = checkin["media"]["items"]
    has_image = is_list(media_items) and Enum.count(media_items) >= 1

    get_key = "GET #{@instance_name}:#{checkin_id}"

    cond do
      String.match?(checkin_comment, ~r/#shh/) ->
        {:error, checkin}
      is_nil(checkin["beer"]) ->
        {:error, checkin}
      @redis.command("#{get_key}:with-image") == {:ok, "1"} ->
        {:error, checkin}
      @redis.command("#{get_key}:without-image") == {:ok, "1"} and not has_image ->
        {:error, checkin}
      true ->
        {:ok, checkin}
    end
  end

  @doc """
  Adds an attachment to the checkin's attachments list.

  ## Example

      iex> Slacktapped.add_attachment({:ok, %{"foo" => "bar"}}, %{"attachments" => []})
      {:ok, %{"attachments" => [%{"foo" => "bar"}]}, %{"foo" => "bar"}}

  """
  def add_attachment({:ok, attachment}, checkin) do
    new_attachments = checkin["attachments"] ++ [attachment]
    checkin = Map.put(checkin, "attachments", new_attachments)
    {:ok, checkin, attachment}
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
