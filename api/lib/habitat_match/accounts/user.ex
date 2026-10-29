defmodule HabitatMatch.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :phone, :string
    field :locale, :string, default: "en"
    field :stripe_customer_id, :string
    field :deleted_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec)
  end
  def changeset(user, attrs), do: cast(user, attrs, [:email, :password_hash, :phone, :locale, :stripe_customer_id]) |> validate_required([:email, :password_hash]) |> unique_constraint(:email)
end

defmodule HabitatMatch.Accounts.Session do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "sessions" do
    field :token_hash, :binary
    field :csrf_token, :string
    field :expires_at, :utc_datetime_usec
    belongs_to :user, HabitatMatch.Accounts.User, type: :binary_id
    timestamps(type: :utc_datetime_usec)
  end
end
