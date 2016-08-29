use Mix.Config

config :mix_test_watch, clear: true
config :slacktappdex, :slack, Slacktappdex.Slack.Mock
config :slacktappdex, :untappd, Slacktappdex.Untappd.Mock
