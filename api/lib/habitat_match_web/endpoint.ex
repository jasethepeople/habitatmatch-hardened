defmodule HabitatMatchWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :habitat_match
  @session_options [store: :cookie, key: "_habitat_match_session", signing_salt: "session-v1", same_site: "Lax", http_only: true, secure: Mix.env() == :prod]
  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  plug Plug.Session, @session_options
  plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json], pass: ["application/json"], json_decoder: Jason, body_reader: {HabitatMatchWeb.RawBodyReader, :read_body, []}, length: 10_485_760
  plug CORSPlug, origin: fn origin -> origin in Application.get_env(:habitat_match, :allowed_origins, []) end
  plug HabitatMatchWeb.Router
end

defmodule HabitatMatchWeb.RawBodyReader do
  def read_body(conn, opts), do: collect(conn, opts, [])
  defp collect(conn, opts, acc) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        raw = IO.iodata_to_binary([Enum.reverse(acc), body])
        {:ok, body, Plug.Conn.assign(conn, :raw_body, raw)}
      {:more, body, conn} -> collect(conn, opts, [body | acc])
    end
  end
end
