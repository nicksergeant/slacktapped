use Mix.Config

config :slacktapped,
  cowboy_port: 80,
  slack: Slacktapped.Slack.Live,
  untappd: Slacktapped.Untappd.Live
