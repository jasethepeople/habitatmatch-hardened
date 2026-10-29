defmodule HabitatMatch.Repo.Migrations.Initial do
  use Ecto.Migration
  def change do
    execute "create extension if not exists pgcrypto"
    execute "create extension if not exists citext"
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :email, :citext, null: false
      add :password_hash, :text, null: false
      add :phone, :text
      add :locale, :text, null: false, default: "en"
      add :stripe_customer_id, :text
      add :deleted_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end
    create unique_index(:users, [:email])

    create table(:sessions, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :token_hash, :binary, null: false
      add :csrf_token, :text, null: false
      add :expires_at, :utc_datetime_usec, null: false
      timestamps(type: :utc_datetime_usec)
    end
    create unique_index(:sessions, [:token_hash])
    create index(:sessions, [:user_id, :expires_at])

    create table(:buildings, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :text, null: false
      add :address, :text, null: false
      add :city, :text, null: false
      add :state, :text, null: false
      add :postal_code, :text, null: false
      add :units_available, :integer, null: false, default: 0
      add :lottery_date, :date
      add :active, :boolean, null: false, default: true
      add :authority_url, :text
      timestamps(type: :utc_datetime_usec)
    end
    create index(:buildings, [:active, :lottery_date])

    create table(:applications, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :household_size, :integer, null: false
      add :annual_income_cents, :bigint, null: false
      add :preferences, :map, null: false, default: %{}
      add :status, :text, null: false, default: "draft"
      add :submitted_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end
    create index(:applications, [:user_id, :inserted_at])

    create table(:application_buildings, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :application_id, references(:applications, type: :uuid, on_delete: :delete_all), null: false
      add :building_id, references(:buildings, type: :uuid, on_delete: :delete_all), null: false
      add :status, :text, null: false, default: "pending"
      add :position, :integer
      add :turn_estimate_days, :integer
      timestamps(type: :utc_datetime_usec)
    end
    create unique_index(:application_buildings, [:application_id, :building_id])
    create index(:application_buildings, [:building_id, :status, :position])

    create table(:documents, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :filename, :text, null: false
      add :content_type, :text, null: false
      add :size_bytes, :bigint, null: false
      add :sha256, :binary, null: false
      add :storage_key, :text, null: false
      add :expires_at, :date, null: false
      add :deleted_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end
    create index(:documents, [:user_id, :expires_at])

    create table(:lottery_audits, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :building_id, references(:buildings, type: :uuid, on_delete: :restrict), null: false
      add :commitment, :binary, null: false
      add :seed_ciphertext, :binary, null: false
      add :algorithm, :text, null: false
      add :drawn_at, :utc_datetime_usec, null: false
    end
    create index(:lottery_audits, [:building_id, :drawn_at])

    create table(:turnover_events, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :building_id, references(:buildings, type: :uuid, on_delete: :delete_all), null: false
      add :event_date, :date, null: false
      add :units_turned, :integer, null: false
    end

    create table(:authority_connections, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :text, null: false
      add :base_url, :text, null: false
      add :auth_type, :text, null: false
      add :encrypted_credentials, :binary, null: false
      add :enabled, :boolean, null: false, default: true
      timestamps(type: :utc_datetime_usec)
    end

    # PostgreSQL RLS is forced even for the table owner. App requests set app.user_id inside a transaction.
    for table <- ~w(applications application_buildings documents)a do
      execute "alter table #{table} enable row level security"
      execute "alter table #{table} force row level security"
    end
    execute "create policy applications_self on applications using (user_id = nullif(current_setting('app.user_id', true), '')::uuid) with check (user_id = nullif(current_setting('app.user_id', true), '')::uuid)"
    execute "create policy application_buildings_self on application_buildings using (exists (select 1 from applications a where a.id = application_id and a.user_id = nullif(current_setting('app.user_id', true), '')::uuid)) with check (exists (select 1 from applications a where a.id = application_id and a.user_id = nullif(current_setting('app.user_id', true), '')::uuid))"
    execute "create policy documents_self on documents using (user_id = nullif(current_setting('app.user_id', true), '')::uuid) with check (user_id = nullif(current_setting('app.user_id', true), '')::uuid)"
  end
end
