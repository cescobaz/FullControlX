defmodule FullControlX.Repo do
  use Ecto.Repo,
    otp_app: :fullcontrol_x,
    adapter: Ecto.Adapters.SQLite3
end
