defmodule HabitatMatch.Application do
  use Application
  def start(_type, _args) do
    children = [HabitatMatch.Repo, HabitatMatch.RateLimit, HabitatMatch.DocumentExpiryWorker, {Finch, name: HabitatMatch.Finch}, {Phoenix.PubSub, name: HabitatMatch.PubSub}, HabitatMatchWeb.Endpoint]
    opts = [strategy: :one_for_one, name: HabitatMatch.Supervisor]
    Supervisor.start_link(children, opts)
  end
  def config_change(changed, _new, removed), do: HabitatMatchWeb.Endpoint.config_change(changed, removed)
end
