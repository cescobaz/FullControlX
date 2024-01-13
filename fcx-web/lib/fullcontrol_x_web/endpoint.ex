defmodule FullControlXWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :fullcontrol_x

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_fullcontrol_x_key",
    signing_salt: "pvpJgHfT"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :fullcontrol_x,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)

  defp files(conn, _params) do
    with {:ok, files_path} <- Application.fetch_env(:fullcontrol_x, :files_path) do
      opts =
        Plug.Static.init(
          at: "/files",
          from: files_path,
          gzip: false
        )

      Plug.Static.call(conn, opts)
    else
      _ -> conn
    end
  end

  plug :files, nil

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :fullcontrol_x
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug FullControlXWeb.Router
end
