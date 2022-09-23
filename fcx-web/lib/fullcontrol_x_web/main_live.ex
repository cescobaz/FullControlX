defmodule FullControlXWeb.MainLive do
  use FullControlXWeb, :live_view

  def mount(_params, _session, socket) do
    info = FullControlX.Driver.system_info(FullControlX.Driver)
    FullControlX.Driver.apps_observe(FullControlX.Driver)
    apps = FullControlX.Driver.ui_apps(FullControlX.Driver)

    {:ok,
     assign(socket, :info, info)
     |> assign(:apps, apps)}
  end

  def render(assigns) do
    ~H"""
    <.header title="FullControlX" />
    <%= for {key, value} <- @info do %>
      <div>
        <%= "#{key}: #{value}" %>
      </div>
    <% end %>
    <div class="grow">
      
    </div>
    <ul class="flex gap-2 overflow-x-scroll scrollbar-hidden scroll-smooth">
      <%= for app <- @apps do %>
        <li class="text-center">
          <%= "#{Map.get(app, "localized_name")}" %>
          <%= if Map.get(app, "focus") do %>
            <div>
              focus
            </div>
          <% end %>
        </li>
      <% end %>
    </ul>
    """
  end
end
