defmodule HabitatMatch.Housing.Application do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "applications" do
    belongs_to :user, HabitatMatch.Accounts.User, type: :binary_id
    field :household_size, :integer
    field :annual_income_cents, :integer
    field :preferences, :map, default: %{}
    field :status, :string, default: "draft"
    field :submitted_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec)
  end
  def changeset(a, attrs), do: cast(a, attrs, [:user_id, :household_size, :annual_income_cents, :preferences, :status]) |> validate_required([:user_id, :household_size, :annual_income_cents]) |> validate_number(:household_size, greater_than: 0) |> validate_number(:annual_income_cents, greater_than_or_equal_to: 0) |> put_change(:submitted_at, DateTime.utc_now())
end

defmodule HabitatMatch.Housing.ApplicationBuilding do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "application_buildings" do
    belongs_to :application, HabitatMatch.Housing.Application, type: :binary_id
    belongs_to :building, HabitatMatch.Housing.Building, type: :binary_id
    field :status, :string, default: "pending"
    field :position, :integer
    field :turn_estimate_days, :integer
    timestamps(type: :utc_datetime_usec)
  end
end
