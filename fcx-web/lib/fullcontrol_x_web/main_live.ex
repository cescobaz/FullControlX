defmodule FullControlXWeb.MainLive do
  use FullControlXWeb, :live_view

  def mount(_params, _session, socket) do
    info = FullControlX.Driver.system_info(FullControlX.Driver)
    apps = FullControlX.Driver.ui_apps(FullControlX.Driver)

    {:ok,
     assign(socket, :info, info)
     |> assign(:apps, apps)}
  end

  def render(assigns) do
    ~H"""
    <h1>System info</h1>
    <%= for {key, value} <- @info do %>
      <div>
        <%= "#{key}: #{value}" %>
      </div>
    <% end %>
    <h2>Apps</h2>
    <%= for app <- @apps do %>
      <div>
        <%= "#{Map.get(app, "localized_name")}" %>
      </div>
    <% end %>
    """
  end
end
