use Mix.Config

IO.puts "============="
IO.puts System.get_env("PORT")
IO.puts "============="

{port, _} = Integer.parse(System.get_env("PORT"))

config :slacktapped,
  cowboy_port: 5000,
  slack: Slacktapped.Slack.Live,
  untappd: Slacktapped.Untappd.Live
