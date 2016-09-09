use Mix.Config

config :quantum, cron: [
  "* * * * *": {Slacktapped, :main}
]

config :slacktapped,
  cowboy_port: 5000,
  instance_name: System.get_env("INSTANCE_NAME"),
  redis: Slacktapped.Redis.Live,
  redis_host: System.get_env("REDIS_HOST"),
  redis_port: 6379,
  slack: Slacktapped.Slack.Live,
  untappd: Slacktapped.Untappd.Live
