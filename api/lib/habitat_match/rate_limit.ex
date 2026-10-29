defmodule HabitatMatch.RateLimit do
  use Hammer, backend: :ets
  def allow(conn, bucket, limit, scale_ms) do
    ip = conn.remote_ip |> :inet.ntoa() |> to_string()
    case hit(bucket <> ":" <> ip, scale_ms, limit) do
      {:allow, _} -> :ok
      {:deny, retry} -> {:error, retry}
    end
  end
end
