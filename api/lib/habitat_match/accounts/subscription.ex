defmodule HabitatMatch.Accounts.Subscription do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "subscriptions" do
    belongs_to :user, HabitatMatch.Accounts.User, type: :binary_id
    field :stripe_subscription_id, :string
    field :stripe_customer_id, :string
    field :status, :string
    field :price_id, :string
    field :current_period_end, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec)
  end
end
