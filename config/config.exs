use Mix.Config

config :quantum, cron: [
  "* * * * *": {Slacktapped, :main}
]

import_config "#{Mix.env}.exs"
