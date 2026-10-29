defmodule HabitatMatchWeb.AuthController do
  use HabitatMatchWeb, :controller
  alias HabitatMatch.Auth

  def register(conn, params) do
    with {:ok, user} <- Auth.register(params),
         {:ok, token, csrf} <- Auth.create_session(user.id) do
      conn
      |> put_session("session_token", token)
      |> json(%{user: %{id: user.id, email: user.email, locale: user.locale}, csrf_token: csrf})
    else
      {:error, reason} -> conn |> put_status(:unprocessable_entity) |> json(%{error: Atom.to_string(reason)})
    end
  end

  def login(conn, %{"email" => email, "password" => password}) when is_binary(email) and is_binary(password) do
    email = String.downcase(String.trim(email))

    case HabitatMatch.Repo.get_by(HabitatMatch.Accounts.User, email: email) do
      nil -> fail(conn)
      user ->
        if is_nil(user.deleted_at) and Argon2.verify_pass(password, user.password_hash), do: session(conn, user), else: fail(conn)
    end
  end

  def login(conn, _), do: fail(conn)

  def logout(conn, _params) do
    unless Auth.csrf_valid?(conn), do: throw(:csrf)
    conn |> delete_session("session_token") |> json(%{ok: true})
  catch
    :throw, :csrf -> conn |> put_status(:forbidden) |> json(%{error: "csrf_failed"})
  end

  def me(conn, _), do: json(conn, %{user: conn.assigns.current_user})
  def csrf(conn, _), do: json(conn, %{csrf_token: conn.assigns.current_user.csrf_token})

  defp session(conn, user) do
    {:ok, token, csrf} = Auth.create_session(user.id)
    conn |> put_session("session_token", token) |> json(%{user: %{id: user.id, email: user.email, locale: user.locale}, csrf_token: csrf})
  end

  defp fail(conn), do: conn |> put_status(:unauthorized) |> json(%{error: "invalid_credentials"})
end
