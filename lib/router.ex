defmodule Slacktapped.Router do
  @moduledoc """
  Sets up two routes:

  - `/` returns a 200 with a fancy message. Mostly used to verify bot health.
  - `/search` responds to Slack slash commands.
  """
  use Plug.Router

  plug Plug.Parsers, parsers: [:urlencoded]

  plug :match
  plug :dispatch

  get "/", do: send_resp(conn, 200, "Yessum?")

  post("/search") do
    case Slacktapped.Search.Untappd.handle_search(conn.params) do
      {:ok, response} ->
        conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Poison.encode!(response))
        IO.puts "Success in search post"
      {:error, _} ->
        IO.puts "Error in search post"
        conn |> send_resp(404, "")
    end
  end

  match _ do
    send_resp(conn, 404, "Page not found.")
  end
end 
