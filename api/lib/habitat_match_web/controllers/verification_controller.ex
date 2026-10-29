defmodule HabitatMatchWeb.VerificationController do
  use HabitatMatchWeb, :controller
  def start(conn, %{"phone" => phone, "locale" => locale}) do
    case HabitatMatch.Twilio.start_verification(phone, locale) do {:ok, d} -> json(conn, %{status: d["status"]}); _ -> conn |> put_status(:bad_gateway) |> json(%{error: "verification_provider_error"}) end
  end
  def start(conn, %{"phone" => phone}), do: start(conn, %{"phone" => phone, "locale" => "en"})
  def check(conn, %{"phone" => phone, "code" => code}) do
    case HabitatMatch.Twilio.check_verification(phone, code) do
      {:ok, %{"status" => "approved"}} -> json(conn, %{verified: true})
      {:ok, _} -> conn |> put_status(:unprocessable_entity) |> json(%{verified: false})
      _ -> conn |> put_status(:bad_gateway) |> json(%{error: "verification_provider_error"})
    end
  end
end
