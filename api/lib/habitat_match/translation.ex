defmodule HabitatMatch.Translation do
  def translate(text, source, target) when is_binary(text) and byte_size(text) <= 20_000 do
    url = System.fetch_env!("TRANSLATION_URL")
    key = System.fetch_env!("TRANSLATION_API_KEY")
    body = Jason.encode!(%{q: text, source: source, target: target, format: "text"})
    req = Finch.build(:post, url, [{"content-type", "application/json"}, {"authorization", "Bearer " <> key}], body)
    case Finch.request(req, HabitatMatch.Finch) do
      {:ok, %Finch.Response{status: s, body: b}} when s in 200..299 -> Jason.decode(b)
      {:ok, _} -> {:error, :translation_provider_error}
      {:error, _} -> {:error, :translation_network_error}
    end
  end
  def translate(_, _, _), do: {:error, :text_too_large}
end
