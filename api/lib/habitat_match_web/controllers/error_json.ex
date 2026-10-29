defmodule HabitatMatchWeb.ErrorJSON do
  def render(template, _assigns), do: %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
end

defmodule HabitatMatchWeb.FallbackController do
  use HabitatMatchWeb, :controller
  def not_found(conn, _), do: conn |> put_status(:not_found) |> json(%{error: "not_found"})
end
