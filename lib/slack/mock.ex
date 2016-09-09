defmodule Slacktapped.Slack.Mock do
  require Logger

  def post(_attachments) do
    # IO.inspect(checkin["attachments"])
    :ok
  end
end
