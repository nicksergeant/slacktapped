use Mix.Config

config :mix_test_watch, clear: true
config :slacktapped,
  cowboy_port: 8000,
  slack: Slacktapped.Slack.Live,
  untappd: Slacktapped.Untappd.Mock
