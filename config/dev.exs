use Mix.Config

config :mix_test_watch, clear: true
config :slacktapped, :slack, Slacktapped.Slack.Mock
config :slacktapped, :untappd, Slacktapped.Untappd.Mock
