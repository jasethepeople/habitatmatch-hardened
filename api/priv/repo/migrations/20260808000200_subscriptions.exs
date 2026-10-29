defmodule HabitatMatch.Repo.Migrations.Subscriptions do
  use Ecto.Migration
  def change do
    create table(:subscriptions, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :stripe_subscription_id, :text, null: false
      add :stripe_customer_id, :text, null: false
      add :status, :text, null: false
      add :price_id, :text
      add :current_period_end, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end
    create unique_index(:subscriptions, [:stripe_subscription_id])
    create index(:subscriptions, [:user_id, :status])
    execute "alter table subscriptions enable row level security"
    execute "alter table subscriptions force row level security"
    execute "create policy subscriptions_self on subscriptions using (user_id = nullif(current_setting('app.user_id', true), '')::uuid) with check (user_id = nullif(current_setting('app.user_id', true), '')::uuid)"
  end
end
