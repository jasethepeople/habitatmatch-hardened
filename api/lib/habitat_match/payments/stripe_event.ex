defmodule HabitatMatch.Payments.StripeEvent do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "stripe_events" do
    field :event_id, :string
    field :received_at, :utc_datetime_usec
  end
  def changeset(event, attrs), do: cast(event, attrs, [:event_id, :received_at]) |> validate_required([:event_id, :received_at]) |> unique_constraint(:event_id)
end
