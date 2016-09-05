use Mix.Config

config :quantum, cron: [
  "* * * * *": {Slacktapped, :debg}
]

import_config "#{Mix.env}.exs"
