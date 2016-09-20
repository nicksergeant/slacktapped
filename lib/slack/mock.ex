defmodule Slacktapped.Slack.Mock do
  require Logger

  @doc """
  Pretends to make a request to the configured Slack webhook URL with the provided
  attachments. Just a stub for debugging and testing, really.

  ## Example

      iex> Slacktapped.Slack.Live.post([%{}, %{}])
      :ok

  """
  def post(attachments) do
    :ok
  end
end
