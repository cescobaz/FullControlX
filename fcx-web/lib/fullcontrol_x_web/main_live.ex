defmodule FullControlXWeb.MainLive do
  use FullControlXWeb, :live_view

  def mount(_params, _session, socket) do
    info = FullControlX.system_info()
    FullControlX.Driver.apps_observe(FullControlX.Driver)
    apps = FullControlX.apps_ui()

    {:ok,
     assign(socket, :info, info)
     |> assign(:apps, apps)
     |> assign(:touches, %{})
     |> assign(:still_touches, %{})
     |> assign(:delayed_action, nil)
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

  defp compute_time_delta(touch, touches_p) do
    %{"id" => id, "ts" => ts} = touch

    with %{"ts" => ts_p} <- Map.get(touches_p, id) do
      ts - ts_p
    else
      _ -> nil
    end
  end

  defp compute_max_time_delta(touches, touches_p) do
    Enum.reduce(touches, 0, fn touch, dt_max ->
      with true <- dt_max != nil,
           dt when not is_nil(dt) <- compute_time_delta(touch, touches_p) do
        max(dt, dt_max)
      else
        _ -> nil
      end
    end)
  end

  @action_delay 300
  @click_max_time 250
  defp touch_in_time?(touches, still_touches) do
    with dt when not is_nil(dt) <- compute_max_time_delta(touches, still_touches) do
      dt < @click_max_time
    else
      _ -> false
    end
  end

  def compute_delta(touch, touches_p) do
    %{"id" => id, "x" => x, "y" => y} = touch
    %{"x" => x_p, "y" => y_p} = Map.get(touches_p, id) || touch
    {x - x_p, y - y_p}
  end

  def compute_max_delta(touches, touches_p) do
    Enum.reduce(touches, {0, 0}, fn touch, {dx_max, dy_max} ->
      {dx, dy} = compute_delta(touch, touches_p)

      {
        if(abs(dx) > abs(dx_max), do: dx, else: dx_max),
        if(abs(dy) > abs(dy_max), do: dy, else: dy_max)
      }
    end)
  end

  def compute_avg_delta([], _touches_p) do
    {0, 0}
  end

  def compute_avg_delta(touches, touches_p) do
    {count, dx_sum, dy_sum} =
      Enum.reduce(touches, {0, 0, 0}, fn touch, {count, dx_sum, dy_sum} ->
        {dx, dy} = compute_delta(touch, touches_p)
        {count + 1, dx_sum + dx, dy_sum + dy}
      end)

    {dx_sum / count, dy_sum / count}
  end

  defp put_touches(touches_p, touches) do
    Enum.reduce(touches, touches_p, fn %{"id" => id} = touch, touches_p ->
      Map.put(touches_p, id, touch)
    end)
  end

  defp delete_touches(touches_p, touches) do
    Enum.reduce(touches, touches_p, fn %{"id" => id}, touches_p ->
      Map.delete(touches_p, id)
    end)
  end

  defp handle_touch(socket, "touchstart", touches, touches_p) do
    %{still_touches: still_touches} = socket.assigns

    assign(socket, :touches, put_touches(touches_p, touches))
    |> assign(:still_touches, put_touches(still_touches, touches))
  end

  defp handle_touch(socket, "touchend", touches, touches_p) do
    %{still_touches: still_touches, delayed_action: delayed_action} = socket.assigns

    socket =
      case {Enum.count(still_touches), Enum.count(touches), delayed_action} do
        {2, 2, nil} ->
          if touch_in_time?(touches, still_touches) do
            IO.inspect(action: :right_click)
            FullControlX.mouse_right_click()
          end

          socket

        {2, 1, nil} ->
          if touch_in_time?(touches, still_touches) do
            assign(socket, :delayed_action, :right_click)
          else
            socket
          end

        {1, 1, :right_click} ->
          if touch_in_time?(touches, still_touches) do
            IO.inspect(action: :right_click)
            FullControlX.mouse_right_click()
          end

          assign(socket, :delayed_action, nil)

        {1, 1, nil} ->
          if touch_in_time?(touches, still_touches) do
            timer = Process.send_after(self(), :left_click, @action_delay)

            assign(socket, :delayed_action, :left_click)
            |> assign(:timer, timer)
          else
            socket
          end

        {1, 1, :left_click} ->
          if touch_in_time?(touches, still_touches) do
            IO.inspect(action: :double_click)
            FullControlX.mouse_double_click()

            with %{timer: timer} when not is_nil(timer) <- socket.assigns do
              Process.cancel_timer(timer)
            end

            assign(socket, :delayed_action, nil)
          else
            socket
          end

        _ ->
          socket
      end

    assign(socket, :touches, delete_touches(touches_p, touches))
    |> assign(:still_touches, delete_touches(still_touches, touches))
  end

  defp handle_touch(socket, "touchcancel", touches, touches_p) do
    assign(socket, :touches, delete_touches(touches_p, touches))
    |> assign(:still_touches, %{})
  end

  defp handle_touch(socket, "touchmove", touches, touches_p) do
    {dx, dy} = compute_avg_delta(touches, touches_p)

    case Enum.count(touches_p) do
      1 ->
        FullControlX.mouse_move(dx, dy)

      2 ->
        IO.inspect(scroll: {dx, dy})
        FullControlX.mouse_scroll_wheel(dx, dy)

      3 ->
        IO.inspect(drag: {dx, dy})

      _ ->
        IO.inspect("ignore")
    end

    assign(socket, :touches, put_touches(touches_p, touches))
    |> assign(:still_touches, %{})
  end

  def handle_info(action, socket) do
    IO.inspect(action: action)
    FullControlX.mouse_left_click()

    with %{delayed_action: ^action} <- socket.assigns do
      {:noreply, assign(socket, :delayed_action, nil)}
    else
      _ ->
        {:noreply, socket}
    end
  end

  @touch_events ["touchstart", "touchend", "touchcancel", "touchmove"]
  def handle_event(event, params, socket) when event in @touch_events do
    %{touches: touches_p} = socket.assigns
    touches = Map.get(params, "touches") || []

    {:noreply, handle_touch(socket, event, touches, touches_p)}
  end
end
