import Config

config :nostrum,
  token: System.get_env("DISCORD_TOKEN"),
  shards: 1

config :logger,
  level: :warn

config :sudo_bot,
  config_file_name: "config.json"

import_config "#{config_env()}.exs"
