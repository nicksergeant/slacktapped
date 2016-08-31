defmodule Slacktappdex.Slack.Mock do
  require Logger

  def post(message) do
    Logger.info("[Slack] #{message}")
    {:ok, message}
  end
end
