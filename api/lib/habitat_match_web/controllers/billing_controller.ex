defmodule HabitatMatchWeb.BillingController do
  use HabitatMatchWeb, :controller
  alias HabitatMatch.Payments
  def show(conn, _), do: json(conn, %{plans: Payments.plans(), subscription: Repo.transaction_as(conn.assigns.current_user.id, fn -> Repo.get_by(HabitatMatch.Accounts.Subscription, user_id: conn.assigns.current_user.id, status: "active") end) |> elem(1)})
  def checkout(conn, %{"plan_id" => plan}) do
    unless HabitatMatch.Auth.csrf_valid?(conn), do: throw(:csrf)
    case Payments.checkout(conn.assigns.current_user.id, plan) do
      {:ok, session} -> json(conn, %{url: session["url"]})
      {:error, _} -> conn |> put_status(:bad_gateway) |> json(%{error: "payment_provider_error"})
    end
  catch :throw, :csrf -> conn |> put_status(:forbidden) |> json(%{error: "csrf_failed"})
  end
  def portal(conn, _) do
    unless HabitatMatch.Auth.csrf_valid?(conn), do: throw(:csrf)
    user = Repo.get!(HabitatMatch.Accounts.User, conn.assigns.current_user.id)
    if user.stripe_customer_id do
      case Payments.portal(user.stripe_customer_id) do {:ok, s} -> json(conn, %{url: s["url"]}); _ -> conn |> put_status(:bad_gateway) |> json(%{error: "payment_provider_error"}) end
    else conn |> put_status(:unprocessable_entity) |> json(%{error: "billing_not_configured"}) end
  catch :throw, :csrf -> conn |> put_status(:forbidden) |> json(%{error: "csrf_failed"})
  end
end
