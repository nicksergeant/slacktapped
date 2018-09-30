use Mix.Config

config :slacktapped, Slacktapped.Scheduler,
  jobs: [
    {"* * * * *",      {Slacktapped, :main, []}},
  ]

config :slacktapped,
  beersearch: Slacktapped.BeerSearch.Live,
  redis: Slacktapped.Redis.Live,
  redis_port: 6379,
  slack: Slacktapped.Slack.Live,
  untappd: Slacktapped.Untappd.Live
