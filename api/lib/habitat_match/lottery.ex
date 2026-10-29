defmodule HabitatMatch.Lottery do
  import Ecto.Query
  alias HabitatMatch.Repo
  alias HabitatMatch.Housing.{ApplicationBuilding, LotteryAudit}

  def rank(ids, seed) when is_binary(seed), do: Enum.sort_by(ids, fn id -> :crypto.hash(:sha256, seed <> id) end)

  def draw(building_id, winners) when is_integer(winners) and winners > 0 do
    entries = from(a in ApplicationBuilding, where: a.building_id == ^building_id and a.status == "pending", select: a.id, order_by: [asc: a.id]) |> Repo.all()
    if entries == [], do: {:error, :no_entries}, else: draw_entries(building_id, entries, winners)
  end

  defp draw_entries(building_id, entries, winners) do
    nonce = :crypto.strong_rand_bytes(32)
    precommit = :crypto.hash(:sha256, nonce)

    with {:ok, audit} <- Repo.insert(%LotteryAudit{building_id: building_id, commitment: precommit, seed_ciphertext: <<>>, algorithm: "precommit=sha256(server_nonce); seed=sha256(nist_beacon_output || server_nonce); rank=sha256(seed || application_building_id)", drawn_at: DateTime.utc_now()}),
         {:ok, beacon} <- public_beacon(),
         seed <- :crypto.hash(:sha256, beacon <> nonce),
         ranked <- rank(entries, seed),
         selected <- Enum.take(ranked, min(winners, length(ranked))),
         {:ok, result} <- Repo.transaction(fn ->
           Enum.with_index(ranked, 1) |> Enum.each(fn {id, pos} -> Repo.update_all(from(a in ApplicationBuilding, where: a.id == ^id), set: [position: pos, status: if(id in selected, do: "selected", else: "waitlisted")]) end)
           {:ok, updated} = Repo.update(Ecto.Changeset.change(audit, seed_ciphertext: nonce))
           %{selected: selected, commitment: precommit, beacon: beacon, nonce: nonce, audit_id: updated.id}
         end) do
      {:ok, result}
    end
  end

  defp public_beacon do
    req = Finch.build(:get, "https://beacon.nist.gov/beacon/2.0/pulse/last", [{"accept", "application/json"}])
    case Finch.request(req, HabitatMatch.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        with {:ok, json} <- Jason.decode(body),
             value when is_binary(value) <- get_in(json, ["pulse", "outputValue"]),
             {:ok, bytes} <- Base.decode16(value, case: :mixed), do: {:ok, bytes}, else: _ -> {:error, :invalid_beacon}
      _ -> {:error, :beacon_unavailable}
    end
  end
end
