use Mix.Config

config :slacktapped,
  cowboy_port: System.get_env("PORT"),
  slack: Slacktapped.Slack.Live,
  untappd: Slacktapped.Untappd.Live
