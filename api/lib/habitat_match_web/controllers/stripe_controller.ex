defmodule HabitatMatchWeb.StripeController do
  use HabitatMatchWeb, :controller
  import Ecto.Query

  def webhook(conn, _) do
    payload = conn.assigns[:raw_body] || ""
    signature = get_req_header(conn, "stripe-signature") |> List.first()
    secret = System.get_env("STRIPE_WEBHOOK_SECRET")

    cond do
      not is_binary(secret) or secret == "" -> conn |> put_status(:service_unavailable) |> json(%{error: "webhook_not_configured"})
      true -> process(conn, payload, signature, secret)
    end
  end

  defp process(conn, payload, signature, secret) do
    case verify_signature(payload, signature, secret) do
      :ok ->
        with {:ok, event} <- Jason.decode(payload),
             event_id when is_binary(event_id) <- event["id"],
             {:ok, _} <- record_event(event_id) do
          handle(event)
          json(conn, %{received: true})
        else
          {:error, :duplicate} -> json(conn, %{received: true})
          _ -> conn |> put_status(:bad_request) |> json(%{error: "invalid_payload"})
        end
      :error -> conn |> put_status(:bad_request) |> json(%{error: "invalid_signature"})
    end
  end

  defp record_event(event_id) do
    case HabitatMatch.Repo.insert(HabitatMatch.Payments.StripeEvent.changeset(%HabitatMatch.Payments.StripeEvent{}, %{event_id: event_id, received_at: DateTime.utc_now()})) do
      {:ok, event} -> {:ok, event}
      {:error, %Ecto.Changeset{errors: [event_id: {_, opts}]}} when opts[:constraint] == :unique -> {:error, :duplicate}
      {:error, _} -> {:error, :record_failed}
    end
  end

  defp handle(%{"type" => "checkout.session.completed", "data" => %{"object" => %{"metadata" => %{"user_id" => user_id}, "customer" => customer}}}) when is_binary(user_id) and is_binary(customer) do
    case HabitatMatch.Repo.get(HabitatMatch.Accounts.User, user_id) do
      nil -> :ok
      user -> HabitatMatch.Repo.update!(Ecto.Changeset.change(user, stripe_customer_id: customer))
    end
  end

  defp handle(%{"type" => type, "data" => %{"object" => obj}}) when type in ["customer.subscription.created", "customer.subscription.updated", "customer.subscription.deleted"] do
    customer = obj["customer"]
    case HabitatMatch.Repo.one(from u in HabitatMatch.Accounts.User, where: u.stripe_customer_id == ^customer, select: u) do
      nil -> :ok
      user ->
        HabitatMatch.Repo.transaction_as(user.id, fn ->
          attrs = %{user_id: user.id, stripe_subscription_id: obj["id"], stripe_customer_id: customer, status: obj["status"], price_id: get_in(obj, ["items", "data", Access.at(0), "price", "id"]), current_period_end: if(is_integer(obj["current_period_end"]), do: DateTime.from_unix!(obj["current_period_end"]), else: nil)}
          case HabitatMatch.Repo.get_by(HabitatMatch.Accounts.Subscription, stripe_subscription_id: obj["id"]) do
            nil -> HabitatMatch.Repo.insert!(struct(HabitatMatch.Accounts.Subscription, attrs))
            sub -> HabitatMatch.Repo.update!(Ecto.Changeset.change(sub, attrs))
          end
        end)
    end
  end

  defp handle(_), do: :ok

  defp verify_signature(payload, header, secret) when is_binary(header) do
    parts = header |> String.split(",") |> Enum.map(&String.split(&1, "=", parts: 2))
    ts = Enum.find_value(parts, fn ["t", v] -> v; _ -> nil end)
    sigs = for ["v1", v] <- parts, do: v

    with ts when is_binary(ts) <- ts,
         {unix, ""} <- Integer.parse(ts),
         true <- abs(DateTime.to_unix(DateTime.utc_now()) - unix) <= 300 do
      expected = :crypto.mac(:hmac, :sha256, secret, ts <> "." <> payload) |> Base.encode16(case: :lower)
      if Enum.any?(sigs, &secure_compare(expected, &1)), do: :ok, else: :error
    else
      _ -> :error
    end
  end

  defp verify_signature(_, _, _), do: :error
  defp secure_compare(a, b) when byte_size(a) == byte_size(b), do: Plug.Crypto.secure_compare(a, b)
  defp secure_compare(_, _), do: false
end
