defmodule HabitatMatchWeb.Plugs.RateLimit do
  import Plug.Conn
  def init(opts), do: opts
  def call(conn, opts) do
    bucket = Keyword.fetch!(opts, :bucket); limit = Keyword.fetch!(opts, :limit); scale = Keyword.fetch!(opts, :scale)
    case HabitatMatch.RateLimit.allow(conn, bucket, limit, scale) do
      :ok -> conn
      {:error, retry} -> conn |> put_resp_header("retry-after", Integer.to_string(div(retry + 999, 1000))) |> put_status(:too_many_requests) |> Phoenix.Controller.json(%{error: "rate_limited"}) |> halt()
    end
  end
end
