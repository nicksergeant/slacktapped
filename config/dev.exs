use Mix.Config

config :mix_test_watch, clear: true
config :slacktapped,
  beersearch: Slacktapped.BeerSearch.Mock,
  cowboy_port: 8000,
  instance_name: "dev",
  redis: Slacktapped.Redis.Mock,
  redis_port: 6379,
  slack: Slacktapped.Slack.Mock,
  untappd: Slacktapped.Untappd.Mock
