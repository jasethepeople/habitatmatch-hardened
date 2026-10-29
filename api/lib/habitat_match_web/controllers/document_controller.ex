defmodule HabitatMatchWeb.DocumentController do
  use HabitatMatchWeb, :controller
  import Ecto.Query
  alias HabitatMatch.Documents.Document

  def index(conn, _) do
    docs = Repo.transaction_as(conn.assigns.current_user.id, fn ->
      from(d in Document, where: d.user_id == ^conn.assigns.current_user.id and is_nil(d.deleted_at), order_by: [asc: d.expires_at])
      |> Repo.all()
    end) |> unwrap_transaction()

    json(conn, %{documents: Enum.map(docs, &Map.take(&1, [:id, :filename, :content_type, :size_bytes, :expires_at, :inserted_at]))})
  end

  def create(conn, %{"file" => %Plug.Upload{path: src, filename: filename, content_type: type}, "expires_at" => expires_at}) do
    unless HabitatMatch.Auth.csrf_valid?(conn), do: throw(:csrf)

    with {:ok, expires} <- Date.from_iso8601(expires_at),
         true <- expires >= Date.utc_today(),
         {:ok, data} <- File.read(src),
         true <- byte_size(data) <= 10_000_000,
         safe <- Path.basename(filename) |> String.replace(~r/[^A-Za-z0-9._ -]/u, "_") |> String.slice(0, 180),
         digest <- :crypto.hash(:sha256, data),
         root <- System.get_env("DOCUMENT_ROOT", "./private/documents"),
         path <- Path.join([root, conn.assigns.current_user.id, Base.encode16(digest, case: :lower)]),
         :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- File.write(path, HabitatMatch.DocumentCrypto.encrypt(data), [:binary]),
         {:ok, doc} <- insert_document(conn.assigns.current_user.id, safe, type, data, digest, path, expires) do
      json(conn, %{document: Map.take(doc, [:id, :filename, :content_type, :size_bytes, :expires_at])})
    else
      _ -> conn |> put_status(:unprocessable_entity) |> json(%{error: "invalid_document"})
    end
  catch
    :throw, :csrf -> conn |> put_status(:forbidden) |> json(%{error: "csrf_failed"})
  end

  def create(conn, _), do: conn |> put_status(:unprocessable_entity) |> json(%{error: "file_and_expiry_required"})

  def download(conn, %{"id" => id}) do
    doc = Repo.transaction_as(conn.assigns.current_user.id, fn -> Repo.get_by(Document, id: id, user_id: conn.assigns.current_user.id) end) |> unwrap_transaction()

    if doc && is_nil(doc.deleted_at) do
      with {:ok, encrypted} <- File.read(doc.storage_key),
           plaintext when is_binary(plaintext) <- HabitatMatch.DocumentCrypto.decrypt(encrypted) do
        conn
        |> put_resp_content_type(doc.content_type)
        |> put_resp_header("content-disposition", ~s(attachment; filename="#{doc.filename}"))
        |> put_resp_header("x-content-type-options", "nosniff")
        |> send_resp(200, plaintext)
      else
        _ -> conn |> put_status(:internal_server_error) |> json(%{error: "document_unavailable"})
      end
    else
      conn |> put_status(:not_found) |> json(%{error: "not_found"})
    end
  end

  def delete(conn, %{"id" => id}) do
    unless HabitatMatch.Auth.csrf_valid?(conn), do: throw(:csrf)

    result = Repo.transaction_as(conn.assigns.current_user.id, fn ->
      case Repo.get_by(Document, id: id, user_id: conn.assigns.current_user.id) do
        nil -> {:not_found, nil}
        doc ->
          {:ok, _} = Repo.update(Ecto.Changeset.change(doc, deleted_at: DateTime.utc_now()))
          {:deleted, doc}
      end
    end)

    case result do
      {:ok, {:not_found, _}} -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
      {:ok, {:deleted, doc}} -> _ = File.rm(doc.storage_key); json(conn, %{ok: true})
      {:error, _} -> conn |> put_status(:internal_server_error) |> json(%{error: "document_delete_failed"})
    end
  catch
    :throw, :csrf -> conn |> put_status(:forbidden) |> json(%{error: "csrf_failed"})
  end

  defp insert_document(user_id, filename, content_type, data, digest, path, expires) do
    Repo.transaction_as(user_id, fn ->
      Repo.insert(%Document{user_id: user_id, filename: filename, content_type: content_type || "application/octet-stream", size_bytes: byte_size(data), sha256: digest, storage_key: path, expires_at: expires})
    end)
    |> case do
      {:ok, {:ok, doc}} -> {:ok, doc}
      {:ok, {:error, changeset}} -> _ = File.rm(path); {:error, changeset}
      {:error, reason} -> _ = File.rm(path); {:error, reason}
    end
  end

  defp unwrap_transaction({:ok, value}), do: value
  defp unwrap_transaction({:error, reason}), do: raise "transaction failed: #{inspect(reason)}"
end
