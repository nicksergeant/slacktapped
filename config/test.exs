use Mix.Config

config :slacktapped,
  beersearch: Slacktapped.BeerSearch.Mock,
  instance_name: "test",
  redis: Slacktapped.Redis.Mock,
  redis_port: 6379,
  slack: Slacktapped.Slack.Mock,
  untappd: Slacktapped.Untappd.Mock,
  untappd_slash_cmd_token: "abc123"
