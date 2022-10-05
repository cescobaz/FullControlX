defmodule FullControlXWeb.TrackpadLive do
  use FullControlXWeb, :live_view

  alias FullControlX.TrackpadDriver

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, :trackpad, TrackpadDriver.init())
     |> assign(:timer, nil)}
  end

  def render(assigns) do
    ~H"""
    <.header title="Trackpad" />
    <div id="view" class="relative grow">
      <div id="placeholder" class="w-full h-full flex flex-col items-center justify-center">
        <div class="p-4">
          <p><span class="font-semibold">Left click</span>: one tap</p>
          <p><span class="font-semibold">Right click</span>: one tap with two fingers</p>
          <p><span class="font-semibold">Scroll</span>: drag with two fingers</p>
          <p><span class="font-semibold">Drag</span>: one tap and drag or drag with three fingers</p>
        </div>
      </div>
      <div id="trackpad" class="absolute left-0 top-0 h-full w-full" phx-touchstart="touchstart" phx-touchmove="touchmove" phx-touchend="touchend" phx-touchcancel="touchcancel" phx-hook="Trackpad">
      </div>
    </div>
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

      {:drag, dx, dy} ->
        FullControlX.mouse_drag(dx, dy)

      {:scroll, dx, dy} ->
        FullControlX.mouse_scroll_wheel(dx, dy)

      :left_click ->
        FullControlX.mouse_left_click()

      :double_click ->
        FullControlX.mouse_double_click()

      :right_click ->
        FullControlX.mouse_right_click()

      :start_dragging ->
        FullControlX.mouse_left_down()

      :stop_dragging ->
        FullControlX.mouse_left_up()

      _ ->
        nil
    end

    case action do
      {:cancel_timer, _} ->
        cancel_timer(socket)

      {:set_timer, message, time} ->
        assign(socket, :timer, Process.send_after(self(), message, time))

      [action | actions] ->
        execute_trackpad_action(socket, action)
        |> execute_trackpad_action(actions)

      _ ->
        socket
    end
  end
end
