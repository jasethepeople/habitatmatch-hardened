defmodule HabitatMatch.Release do
  @app :habitat_match
  def migrate do
    Application.load(@app)
    for repo <- Application.fetch_env!(@app, :ecto_repos) do
      {:ok, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end
end
