defmodule HabitatMatch.Repo.Migrations.StripeEvents do
  use Ecto.Migration
  def change do
    create table(:stripe_events, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :event_id, :text, null: false
      add :received_at, :utc_datetime_usec, null: false
    end
    create unique_index(:stripe_events, [:event_id])
  end
end
