use Mix.Config

config :ably_sse_demo,
  api_key: System.get_env("API_KEY"),
  channels: System.get_env("CHANNELS"),
  version: "1.1"
