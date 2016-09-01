defmodule Slacktapped.Slack.Mock do
  require Logger

  def post(message, image_url \\ "") do
    # Logger.info("[Slack] #{message}")
    {:ok, message}
  end
end
