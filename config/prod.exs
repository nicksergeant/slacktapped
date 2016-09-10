use Mix.Config

config :quantum, cron: [
  "* * * * *": {Slacktapped, :main}
]

config :slacktapped,
  cowboy_port: 5000,
  redis: Slacktapped.Redis.Live,
  redis_host: "45.79.167.199",
  redis_port: 6379,
  slack: Slacktapped.Slack.Live,
  untappd: Slacktapped.Untappd.Live
