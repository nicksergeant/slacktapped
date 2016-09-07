defmodule Slacktapped do
  use Application
  require Logger

  @slack Application.get_env(:slacktapped, :slack)
  @untappd Application.get_env(:slacktapped, :untappd)

  def debg do
    Logger.info("[Poller] Triggered")
  end

  def start(_type, _args) do
    port = Application.get_env(:slacktapped, :cowboy_port, 8080)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Slacktapped.Router, [], port: port)
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
      |> Enum.take(3) # TODO: Remove for prod.
      |> Enum.each(&(handle_checkin(&1)))
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
          "attachments" => [
            %{
              "author_icon" => nil,
              "author_link" => "https://untappd.com/brewery/",
              "author_name" => nil,
              "color" => "#FFCF0B",
              "fallback" => "Image of this checkin.",
              "footer" => "<https://untappd.com/user/|>",
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
         {:ok, checkin} <- @slack.post(checkin),
         do: {:ok, checkin}
  end

  @doc """
  Determines if a checkin is eligible to be posted to Slack. Checkin is
  ineligible if the checkin_comment contains the text "#shh", or if there is
  no beer.

  ## Examples

      iex> Slacktapped.is_eligible_checkin(%{})
      {:error, %{}}

      iex> Slacktapped.is_eligible_checkin(%{"beer" => %{}})
      {:ok, %{"beer" => %{}}}

      iex> Slacktapped.is_eligible_checkin(%{"checkin_comment" => "#shh"})
      {:error, %{"checkin_comment" => "#shh"}}

  """
  def is_eligible_checkin(checkin) do
    cond do
      is_nil(checkin["beer"]) ->
        {:error, checkin}
      is_nil(checkin["checkin_comment"]) ->
        {:ok, checkin}
      String.match?(checkin["checkin_comment"], ~r/#shh/) ->
        {:error, checkin}
      true ->
        {:ok, checkin}
    end
  end

  @doc """
  Adds an attachment to the checkin's attachments list.

  ## Example

      iex> Slacktapped.add_attachment({:ok, %{"foo" => "bar"}}, %{"attachments" => []})
      {:ok, %{"attachments" => [%{"foo" => "bar"}]}}

  """
  def add_attachment({:ok, attachment}, checkin) do
    new_attachments = checkin["attachments"] ++ [attachment]
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
