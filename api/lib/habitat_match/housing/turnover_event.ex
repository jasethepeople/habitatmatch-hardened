defmodule HabitatMatch.Housing.TurnoverEvent do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "turnover_events" do
    belongs_to :building, HabitatMatch.Housing.Building, type: :binary_id
    field :event_date, :date
    field :units_turned, :integer
  end
end
