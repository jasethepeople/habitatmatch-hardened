defmodule HabitatMatch.Payments do
  def plans do
    [%{id: "provider_starter", name: "Starter", amount: 9900, currency: "usd", interval: "month"}, %{id: "provider_growth", name: "Growth", amount: 29900, currency: "usd", interval: "month"}, %{id: "provider_scale", name: "Scale", amount: 79900, currency: "usd", interval: "month"}]
  end
  def price_id("provider_starter"), do: System.fetch_env!("STRIPE_PRICE_STARTER")
  def price_id("provider_growth"), do: System.fetch_env!("STRIPE_PRICE_GROWTH")
  def price_id("provider_scale"), do: System.fetch_env!("STRIPE_PRICE_SCALE")
  def price_id(_), do: {:error, :invalid_plan}

  def checkout(user_id, plan_id) do
    with price when is_binary(price) <- price_id(plan_id),
         {:ok, body} <- form(%{"mode" => "subscription", "line_items[0][price]" => price, "line_items[0][quantity]" => "1", "success_url" => System.fetch_env!("WEB_URL") <> "/billing/success?session_id={CHECKOUT_SESSION_ID}", "cancel_url" => System.fetch_env!("WEB_URL") <> "/billing", "metadata[user_id]" => user_id}),
         {:ok, resp} <- request(:post, "/v1/checkout/sessions", body) do
      {:ok, resp}
    end
  end
  def portal(customer) do
    with {:ok, body} <- form(%{"customer" => customer, "return_url" => System.fetch_env!("WEB_URL") <> "/billing"}), do: request(:post, "/v1/billing_portal/sessions", body)
  end
  defp form(map), do: {:ok, URI.encode_query(map)}
  defp request(method, path, body) do
    key = System.fetch_env!("STRIPE_SECRET_KEY")
    req = Finch.build(method, "https://api.stripe.com" <> path, [{"authorization", "Bearer " <> key}, {"content-type", "application/x-www-form-urlencoded"}], body)
    case Finch.request(req, HabitatMatch.Finch) do
      {:ok, %Finch.Response{status: s, body: b}} when s in 200..299 -> Jason.decode(b)
      {:ok, _} -> {:error, :payment_provider_error}
      {:error, _} -> {:error, :payment_provider_error}
    end
  end
end
