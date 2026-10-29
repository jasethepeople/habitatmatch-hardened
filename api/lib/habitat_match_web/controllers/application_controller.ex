defmodule HabitatMatchWeb.ApplicationController do
  use HabitatMatchWeb, :controller
  import Ecto.Query
  alias HabitatMatch.Housing.{Application, Building, ApplicationBuilding}
  def create(conn, %{"building_ids" => ids} = params) when is_list(ids) and ids != [] do
    user = conn.assigns.current_user
    unless HabitatMatch.Auth.csrf_valid?(conn), do: throw(:csrf)
    result = Repo.transaction_as(user.id, fn ->
      valid_ids = from(b in Building, where: b.id in ^ids and b.active == true, select: b.id) |> Repo.all()
      if MapSet.size(MapSet.new(valid_ids)) != length(ids), do: Repo.rollback(:invalid_buildings)
      changes = %{user_id: user.id, household_size: params["household_size"], annual_income_cents: params["annual_income_cents"], preferences: params["preferences"] || %{}, status: "submitted"}
      {:ok, app} = Repo.insert(Application.changeset(%Application{}, changes))
      Enum.each(valid_ids, fn bid -> Repo.insert!(%ApplicationBuilding{application_id: app.id, building_id: bid, status: "pending"}) end)
      app
    end)
    case result do {:ok, app} -> json(conn, %{application_id: app.id, status: app.status}); {:error, reason} -> conn |> put_status(:unprocessable_entity) |> json(%{error: to_string(reason)}) end
  catch :throw, :csrf -> conn |> put_status(:forbidden) |> json(%{error: "csrf_failed"})
  end
  def create(conn, _), do: conn |> put_status(:unprocessable_entity) |> json(%{error: "building_ids_required"})
  def index(conn, _) do
    apps = Repo.transaction_as(conn.assigns.current_user.id, fn -> from(a in Application, where: a.user_id == ^conn.assigns.current_user.id, order_by: [desc: a.inserted_at]) |> Repo.all() end) |> elem(1)
    json(conn, %{applications: Enum.map(apps, &Map.take(&1, [:id, :status, :household_size, :annual_income_cents, :submitted_at, :inserted_at]))})
  end
  def show(conn, %{"id" => id}) do
    result = Repo.transaction_as(conn.assigns.current_user.id, fn ->
      case Repo.get_by(Application, id: id, user_id: conn.assigns.current_user.id) do
        nil -> nil
        app ->
          rows = from(ab in ApplicationBuilding, join: b in Building, on: b.id == ab.building_id, where: ab.application_id == ^app.id, select: %{id: ab.id, building_id: b.id, building_name: b.name, status: ab.status, position: ab.position}) |> Repo.all()
          %{app: app, rows: rows}
      end
    end) |> elem(1)
    case result do
      nil -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
      %{app: app, rows: rows} -> json(conn, %{application: app, placements: Enum.map(rows, fn r -> Map.put(r, :turn_estimate_days, if(r.position, do: HabitatMatch.Housing.Waitlist.estimate_days(r.building_id, r.position), else: nil)) end)})
    end
  end
end
