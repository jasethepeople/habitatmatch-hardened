defmodule HabitatMatch.AuthorityClient do
  @moduledoc """Standards-oriented outbound adapter for configured housing-authority REST APIs."""
  def submit_application(connection, application) do
    body = Jason.encode!(%{application_id: application.id, household_size: application.household_size, annual_income_cents: application.annual_income_cents, preferences: application.preferences})
    request(connection, "/applications", body)
  end
  def get_waitlist(connection, remote_id), do: request(connection, "/applications/#{URI.encode(remote_id)}", nil, :get)
  defp request(c, path, body, method \\ :post) do
    headers = [{"accept", "application/json"}, {"authorization", "Bearer " <> c.token}, {"content-type", "application/json"}]
    req = Finch.build(method, String.trim_trailing(c.base_url, "/") <> path, headers, body)
    case Finch.request(req, HabitatMatch.Finch) do
      {:ok, %Finch.Response{status: s, body: b}} when s in 200..299 -> Jason.decode(b)
      {:ok, %Finch.Response{status: s}} -> {:error, {:authority_http_error, s}}
      {:error, e} -> {:error, {:authority_network_error, e}}
    end
  end
end
