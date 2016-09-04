defmodule Slacktapped.Slack.Mock do
  require Logger

  def post(checkin \\ "") do
    # IO.inspect(checkin["attachments"])
    {:ok, checkin}
  end
end
