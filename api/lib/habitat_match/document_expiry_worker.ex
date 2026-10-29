defmodule HabitatMatch.DocumentExpiryWorker do
  use GenServer
  import Ecto.Query
  alias HabitatMatch.Repo
  @interval :timer.hours(24)
  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  def init(state) do
    Process.send_after(self(), :run, 5_000)
    {:ok, state}
  end
  def handle_info(:run, state) do
    notify_expiring()
    Process.send_after(self(), :run, @interval)
    {:noreply, state}
  end
  defp notify_expiring do
    if System.get_env("TWILIO_MESSAGING_SERVICE_SID") && System.get_env("TWILIO_ACCOUNT_SID") && System.get_env("TWILIO_API_KEY") && System.get_env("TWILIO_API_SECRET") do
      do_notify()
    end
  end
  defp do_notify do
    users = from(u in HabitatMatch.Accounts.User, where: not is_nil(u.phone) and is_nil(u.deleted_at), select: {u.id, u.phone}) |> Repo.all()
    target = Date.add(Date.utc_today(), 7)
    Enum.each(users, fn {user_id, phone} ->
      docs = Repo.transaction_as(user_id, fn -> from(d in HabitatMatch.Documents.Document, where: d.expires_at <= ^target and d.expires_at >= ^Date.utc_today() and is_nil(d.deleted_at), select: {d.filename, d.expires_at}) |> Repo.all() end) |> elem(1)
      Enum.each(docs, fn {filename, expires} -> _ = HabitatMatch.Twilio.notify(phone, "HabitatMatch: your document #{filename} expires on #{Date.to_iso8601(expires)}. Please replace it before it expires.") end)
    end
  end
end
