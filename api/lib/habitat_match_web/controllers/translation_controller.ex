defmodule HabitatMatchWeb.TranslationController do
  use HabitatMatchWeb, :controller
  def translate(conn, %{"text" => text, "source" => source, "target" => target}) do
    case HabitatMatch.Translation.translate(text, source, target) do {:ok, d} -> json(conn, d); {:error, _} -> conn |> put_status(:bad_gateway) |> json(%{error: "translation_provider_error"}) end
  end
  def translate(conn, _), do: conn |> put_status(:unprocessable_entity) |> json(%{error: "invalid_translation_request"})
end
