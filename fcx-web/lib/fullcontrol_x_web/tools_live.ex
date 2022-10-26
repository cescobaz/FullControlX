defmodule FullControlXWeb.ToolsLive do
  use FullControlXWeb, :live_view

  def mount(_params, _session, socket) do
    info = FullControlX.system_info() || %{}

    {:ok, assign(socket, :info, info)}
  end

  def render(assigns) do
    ~H"""
    <.header title="Tools" />
    <%= for {key, value} <- @info do %>
      <div>
        <%= "#{key}: #{value}" %>
      </div>
    <% end %>
    <div class="grow flex flex-col justify-end gap-4 pb-4">
      <div class="flex justify-center gap-4">
        <button phx-click="click" value="brightness_up">Brightness Up</button>
        <button phx-click="click" value="brightness_down">Brightness Down</button>
      </div>
      <div class="flex justify-center gap-4">
        <button phx-click="click" value="volume_up">Volume Up</button>
        <button phx-click="click" value="volume_down">Volume Down</button>
        <button phx-click="click" value="volume_mute">Mute</button>
      </div>
    </div>
    """
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end
end
