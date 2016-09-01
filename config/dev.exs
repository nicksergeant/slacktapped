use Mix.Config

config :mix_test_watch, clear: true
config :slacktapped, :slack, Slacktapped.Slack.Live
config :slacktapped, :untappd, Slacktapped.Untappd.Mock
