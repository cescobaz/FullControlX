defmodule FullControlXWeb.CommandsLive do
  use FullControlXWeb, :live_view

  def mount(_params, _session, socket) do
    # FullControlX.Driver.apps_observe(FullControlX.Driver)
    apps = FullControlX.apps_ui() || []

    {:ok, assign(socket, :apps, apps)}
  end

  def render(assigns) do
    ~H"""
    <.header title="FullControlX" />
    <div class="grow"></div>
    <ul class="flex gap-2 overflow-x-scroll scrollbar-hidden scroll-smooth">
      <%= for app <- @apps do %>
        <li class={app_class(app)}>
          <%= "#{Map.get(app, "localized_name")}" %>
        </li>
      <% end %>
    </ul>
    """
  end

  defp app_class(app) do
    class = ["text-center"]

    class =
      if Map.get(app, "focus") do
        Enum.concat(class, ["border-b-2 border-b-blue-600"])
      else
        class
      end

    Enum.join(class, " ")
  end
end
