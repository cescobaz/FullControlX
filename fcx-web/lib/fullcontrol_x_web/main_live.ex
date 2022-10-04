defmodule FullControlXWeb.MainLive do
  use FullControlXWeb, :live_view

  alias FullControlX.TrackpadDriver

  def mount(_params, _session, socket) do
    info = FullControlX.system_info()
    FullControlX.Driver.apps_observe(FullControlX.Driver)
    apps = FullControlX.apps_ui()

    {:ok,
     assign(socket, :info, info)
     |> assign(:apps, apps)
     |> assign(:trackpad, TrackpadDriver.init())
     |> assign(:timer, nil)}
  end

  def render(assigns) do
    ~H"""
    <.header title="FullControlX" />
    <%= for {key, value} <- @info do %>
      <div>
        <%= "#{key}: #{value}" %>
      </div>
    <% end %>
    <div id="view" class="relative grow">
      <div id="placeholder" class="w-full h-full flex flex-col items-center justify-center">
        <h2>Trackpad</h2>
      </div>
      <div id="trackpad" class="absolute left-0 top-0 h-full w-full border border-green-800" phx-touchstart="touchstart" phx-touchmove="touchmove" phx-touchend="touchend" phx-touchcancel="touchcancel" phx-hook="Trackpad">
      </div>
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

  def handle_info(message, socket) do
    %{trackpad: trackpad} = socket.assigns
    %{action: action} = trackpad = TrackpadDriver.handle_info(trackpad, message)

    {:noreply,
     execute_trackpad_action(socket, action)
     |> assign(:trackpad, trackpad)}
  end

  @touch_events ["touchstart", "touchend", "touchcancel", "touchmove"]
  def handle_event(event, params, socket) when event in @touch_events do
    %{trackpad: trackpad} = socket.assigns
    touches = Map.get(params, "touches") || []
    %{action: action} = trackpad = TrackpadDriver.handle_touch(trackpad, event, touches)

    {:noreply,
     execute_trackpad_action(socket, action)
     |> assign(:trackpad, trackpad)}
  end

  defp cancel_timer(socket) do
    with %{timer: timer} when not is_nil(timer) <- socket.assigns do
      Process.cancel_timer(timer)
      assign(socket, :timer, nil)
    else
      _ -> socket
    end
  end

  defp execute_trackpad_action(socket, action) do
    case action do
      {:move, dx, dy} ->
        FullControlX.mouse_move(dx, dy)

      {:scroll, dx, dy} ->
        FullControlX.mouse_scroll_wheel(dx, dy)

      :left_click ->
        FullControlX.mouse_left_click()

      :double_click ->
        FullControlX.mouse_double_click()

      :right_click ->
        FullControlX.mouse_right_click()

      _ ->
        nil
    end

    case action do
      {:cancel_timer, _} ->
        cancel_timer(socket)

      {:set_timer, message, time} ->
        assign(socket, :timer, Process.send_after(self(), message, time))

      _ ->
        socket
    end
  end
end
