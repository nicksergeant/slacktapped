defmodule Slacktapped.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/", do: send_resp(conn, 200, "Yessum?")

  match _ do
    send_resp(conn, 404, "Page not found.")
  end
end 
