defmodule HabitatMatch.Auth do
  import Ecto.Query
  alias HabitatMatch.Repo
  alias HabitatMatch.Accounts.{User, Session}

  def register(attrs) do
    email = attrs["email"] |> String.trim() |> String.downcase()
    password = attrs["password"] || ""
    cond do
      not Regex.match?(~r/\A[^\s@]+@[^\s@]+\.[^\s@]+\z/, email) -> {:error, :invalid_email}
      byte_size(password) < 12 -> {:error, :weak_password}
      String.length(password) > 128 -> {:error, :weak_password}
      Repo.get_by(User, email: email) -> {:error, :email_taken}
      true ->
        cs = User.changeset(%User{id: Ecto.UUID.generate()}, %{email: email, password_hash: Argon2.hash_pwd_salt(password), phone: attrs["phone"], locale: attrs["locale"] || "en"})
        case Repo.insert(cs) do {:ok, user} -> {:ok, user}; {:error, _} -> {:error, :invalid_registration} end
    end
  end

  def create_session(user_id) do
    token = :crypto.strong_rand_bytes(48) |> Base.url_encode64(padding: false)
    hash = :crypto.hash(:sha256, token)
    csrf = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    expires = DateTime.add(DateTime.utc_now(), 60 * 60 * 24 * 30, :second)
    case Repo.insert(%Session{user_id: user_id, token_hash: hash, csrf_token: csrf, expires_at: expires}) do
      {:ok, _} -> {:ok, token, csrf}
      error -> error
    end
  end

  def authenticate(token) do
    hash = :crypto.hash(:sha256, token)
    from(s in Session, join: u in User, on: u.id == s.user_id, where: s.token_hash == ^hash and s.expires_at > ^DateTime.utc_now() and is_nil(u.deleted_at), select: {s, u})
    |> Repo.one()
    |> case do nil -> :error; {session, user} -> {:ok, %{id: user.id, email: user.email, locale: user.locale, csrf_token: session.csrf_token}} end
  end

  def csrf_valid?(conn) do
    header = Plug.Conn.get_req_header(conn, "x-csrf-token") |> List.first()
    header && Plug.Conn.assigns(conn)[:current_user][:csrf_token] == header
  end
end
