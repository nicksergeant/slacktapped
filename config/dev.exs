use Mix.Config

config :mix_test_watch, clear: true
config :slacktapped,
  cowboy_port: 8080,
  slack: Slacktapped.Slack.Mock,
  untappd: Slacktapped.Untappd.Mock
