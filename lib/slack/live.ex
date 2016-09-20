defmodule Slacktapped.Slack.Live do
  @doc """
  Makes a request to the configured Slack webhook URL with the provided
  attachments.

  ## Example

      iex> Slacktapped.Slack.Live.post([%{}, %{}])
      :ok

  """
  def post(attachments) do
    webhook_url = System.get_env("SLACK_WEBHOOK_URL")

    HTTPotion.post(webhook_url, [
      body: Poison.encode!(%{
        attachments: attachments,
        icon_url: "https://slacktapped.s3.amazonaws.com/icon.jpg",
        username: "Untappd",
      }),
      headers: ["Content-Type": "application/json"]
    ])

    :ok
  end
end
