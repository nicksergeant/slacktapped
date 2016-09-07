use Mix.Config

config :slacktapped,
  cowboy_port: 5000,
  slack: Slacktapped.Slack.Live,
  untappd: Slacktapped.Untappd.Live
