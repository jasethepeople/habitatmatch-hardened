defmodule HabitatMatchWeb.Plugs.Auth do
  import Plug.Conn
  alias HabitatMatch.Auth
  def init(opts), do: opts
  def call(conn, _opts) do
    case get_session(conn, "session_token") do
      nil -> conn |> put_status(:unauthorized) |> Phoenix.Controller.json(%{error: "authentication_required"}) |> halt()
      token ->
        case Auth.authenticate(token) do
          {:ok, user} -> assign(conn, :current_user, user)
          :error -> conn |> delete_session("session_token") |> put_status(:unauthorized) |> Phoenix.Controller.json(%{error: "authentication_required"}) |> halt()
        end
    end
  end
end
