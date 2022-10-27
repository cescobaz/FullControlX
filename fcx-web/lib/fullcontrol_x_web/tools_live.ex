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
        <button phx-click="keyboard" value="brightnessup">Brightness Up</button>
        <button phx-click="keyboard" value="brightnessdown">Brightness Down</button>
      </div>
      <div class="flex justify-center gap-4">
        <button phx-click="keyboard" value="volumeup">Volume Up</button>
        <button phx-click="keyboard" value="volumedown">Volume Down</button>
        <button phx-click="keyboard" value="mute">Mute</button>
      </div>
    </div>
    """
  end

  def handle_event("keyboard", %{"value" => symbol}, socket) do
    FullControlX.keyboard_type_symbol(symbol)
    {:noreply, socket}
  end

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)
    {:noreply, socket}
  end
end
