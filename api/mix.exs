defmodule HabitatMatch.MixProject do
  use Mix.Project

  def project do
    [app: :habitat_match, version: "1.0.0", elixir: "~> 1.20", elixirc_paths: elixirc_paths(Mix.env()), start_permanent: Mix.env() == :prod, deps: deps(), aliases: aliases()]
  end

  def application do
    [mod: {HabitatMatch.Application, []}, extra_applications: [:logger, :crypto, :ssl]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.8.9"}, {:phoenix_ecto, "~> 4.6"}, {:ecto_sql, "~> 3.14"},
      {:postgrex, "~> 0.21"}, {:bandit, "~> 1.12"}, {:jason, "~> 1.4"},
      {:argon2_elixir, "~> 4.1"}, {:hammer, "~> 7.4"}, {:finch, "~> 0.23"}, {:cors_plug, "~> 3.0"}, {:plug, "~> 1.18"}, {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    ["setup": ["deps.get", "ecto.setup"], "ecto.setup": ["ecto.create", "ecto.migrate"], "ecto.reset": ["ecto.drop", "ecto.setup"], test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]]
  end
end
