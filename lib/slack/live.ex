defmodule Slacktapped.Slack.Live do
  def post(message, image_url \\ "") do
    webhook_url = System.get_env("SLACK_WEBHOOK_URL")

    HTTPotion.post(webhook_url, [
      body: Poison.encode!(%{
        attachments: [
          %{
            fallback: "Image of this checkin.",
            image_url: image_url
          }
        ],
        icon_url: "https://slacktapped.s3.amazonaws.com/icon.jpg",
        text: message,
        username: "Untappd",
      }),
      headers: ["Content-Type": "application/json"]
    ])

    {:ok, message}
  end
end
