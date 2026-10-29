defmodule HabitatMatch.Housing.Building do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "buildings" do
    field :name, :string
    field :address, :string
    field :city, :string
    field :state, :string
    field :postal_code, :string
    field :units_available, :integer, default: 0
    field :lottery_date, :date
    field :active, :boolean, default: true
    field :authority_url, :string
    timestamps(type: :utc_datetime_usec)
  end
end
