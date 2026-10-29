defmodule HabitatMatchWeb.Plugs.SecurityHeaders do
  import Plug.Conn
  def init(opts), do: opts
  def call(conn, _opts) do
    conn
    |> put_resp_header("x-content-type-options", "nosniff")
    |> put_resp_header("x-frame-options", "DENY")
    |> put_resp_header("referrer-policy", "strict-origin-when-cross-origin")
    |> put_resp_header("permissions-policy", "camera=(), microphone=(), geolocation=()")
    |> put_resp_header("content-security-policy", "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' https://js.stripe.com; frame-src https://js.stripe.com https://checkout.stripe.com; connect-src 'self' https://api.stripe.com")
  end
end
