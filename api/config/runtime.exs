import Config
if config_env() == :prod do
  config :habitat_match, HabitatMatch.Repo,
    url: System.fetch_env!("DATABASE_URL"), pool_size: String.to_integer(System.get_env("POOL_SIZE", "20")), ssl: System.get_env("DB_SSL", "true") == "true"
  config :habitat_match, HabitatMatchWeb.Endpoint,
    adapter: Bandit.PhoenixAdapter,
    http: [ip: {0,0,0,0}, port: String.to_integer(System.get_env("PORT", "4000"))], secret_key_base: System.fetch_env!("SECRET_KEY_BASE"), server: true
  config :habitat_match, :allowed_origins, System.get_env("ALLOWED_ORIGINS", "https://app.habitatmatch.org") |> String.split(",", trim: true)
  config :habitat_match, :cookie_domain, System.get_env("COOKIE_DOMAIN", ".habitatmatch.org")
else
  config :habitat_match, HabitatMatch.Repo, url: System.get_env("DATABASE_URL", "postgres://postgres:postgres@localhost/habitat_match_dev")
  config :habitat_match, HabitatMatchWeb.Endpoint, adapter: Bandit.PhoenixAdapter, http: [ip: {127,0,0,1}, port: 4000], secret_key_base: System.get_env("SECRET_KEY_BASE", String.duplicate("development-secret-", 10))
  config :habitat_match, :allowed_origins, ["http://localhost:5173"]
  config :habitat_match, :cookie_domain, nil
end
