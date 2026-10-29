defmodule HabitatMatch.Housing.Waitlist do
  import Ecto.Query
  alias HabitatMatch.Repo
  def estimate_days(building_id, position) when is_integer(position) and position > 0 do
    since = Date.add(Date.utc_today(), -365)
    days = Date.diff(Date.utc_today(), since)
    turnover = from(t in HabitatMatch.Housing.TurnoverEvent, where: t.building_id == ^building_id and t.event_date >= ^since, select: sum(t.units_turned)) |> Repo.one() || 0
    if turnover > 0, do: round(position * days / turnover), else: nil
  end
end
