use Mix.Config

config :slacktapped, redis_expiration: 2592000

import_config "#{Mix.env}.exs"
