use Mix.Config

# {port, _} = Integer.parse(System.get_env("PORT"))

config :slacktapped,
  cowboy_port: 80,
  slack: Slacktapped.Slack.Live,
  untappd: Slacktapped.Untappd.Live
