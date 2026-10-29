import Config
config :habitat_match, ecto_repos: [HabitatMatch.Repo]
config :habitat_match, HabitatMatchWeb.Endpoint, url: [host: "localhost"], render_errors: [formats: [json: HabitatMatchWeb.ErrorJSON], layout: false], pubsub_server: HabitatMatch.PubSub
config :phoenix, :json_library, Jason
config :logger, :console, format: "$time $metadata[$level] $message\n", metadata: [:request_id]
config :cors_plug, origin: ["http://localhost:5173"]
