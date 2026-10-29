defmodule HabitatMatchWeb.BuildingController do
  use HabitatMatchWeb, :controller
  import Ecto.Query
  def index(conn, _params) do
    buildings = from(b in HabitatMatch.Housing.Building, where: b.active == true, order_by: [asc: b.name]) |> HabitatMatch.Repo.all()
    json(conn, %{buildings: Enum.map(buildings, &Map.take(&1, [:id, :name, :address, :city, :state, :postal_code, :units_available, :lottery_date]))})
  end
end
