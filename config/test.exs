use Mix.Config

config :slacktapped,
  instance_name: "test",
  redis: Slacktapped.Redis.Mock,
  redis_port: 6379,
  slack: Slacktapped.Slack.Mock,
  untappd: Slacktapped.Untappd.Mock
