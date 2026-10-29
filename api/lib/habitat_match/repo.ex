defmodule HabitatMatch.Repo do
  use Ecto.Repo, otp_app: :habitat_match, adapter: Ecto.Adapters.Postgres

  def transaction_as(user_id, fun) when is_binary(user_id) do
    transaction(fn ->
      Ecto.Adapters.SQL.query!(__MODULE__, "select set_config('app.user_id', $1, true)", [user_id])
      fun.()
    end)
  end
end
