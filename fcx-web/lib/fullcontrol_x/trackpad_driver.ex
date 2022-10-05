defmodule FullControlX.TrackpadDriver do
  @click_max_time 250

  def init() do
    %{
      touches: %{},
      waiting_for_timer: false,
      name: :init,
      action: nil
    }
  end

  defp reset(state) do
    state
    |> Map.put(:action, nil)
    |> Map.put(:waiting_for_timer, false)
    |> Map.put(:name, :init)
  end

  def handle_touch(%{name: :init} = state, "touchstart", touches) do
    name =
      case Enum.count(touches) do
        1 -> :one_touch_down
        2 -> :two_touches_down
        3 -> :three_touches_down
        _ -> :many_touches_down
      end

    state
    |> Map.put(:action, nil)
    |> Map.put(:name, name)
    |> put_touches(touches)
  end

  def handle_touch(%{name: :one_touch_down} = state, "touchstart", touches) do
    name =
      case Enum.count(touches) do
        1 -> :two_touches_down
        2 -> :three_touches_down
        _ -> :many_touches_down
      end

    state
    |> Map.put(:action, nil)
    |> Map.put(:name, name)
    |> put_touches(touches)
  end

  def handle_touch(%{name: :will_left_click} = state, "touchstart", touches) do
    case Enum.count(touches) do
      1 ->
        state
        |> Map.put(:action, {:cancel_timer, :left_click})
        |> Map.put(:waiting_for_timer, false)
        |> Map.put(:name, :one_tap_dragging)

      _ ->
        state
    end
    |> put_touches(touches)
  end

  def handle_touch(state, "touchstart", touches) do
    put_touches(state, touches)
  end

  def handle_touch(%{name: :one_touch_down} = state, "touchend", touches) do
    %{touches: touches_s} = state

    if touch_in_time?(touches, touches_s) do
      state
      |> Map.put(:action, {:set_timer, :left_click, 200})
      |> Map.put(:waiting_for_timer, :left_click)
      |> Map.put(:name, :will_left_click)
    else
      state
    end
    |> delete_touches(touches)
  end

  def handle_touch(%{name: :one_tap_dragging} = state, "touchend", touches) do
    %{touches: touches_s} = state

    if touch_in_time?(touches, touches_s) do
      state
      |> Map.put(:action, :double_click)
      |> Map.put(:name, :init)
    else
      state
    end
    |> delete_touches(touches)
  end

  def handle_touch(%{name: :two_touches_down} = state, "touchend", touches) do
    %{touches: touches_s} = state

    case {Enum.count(touches), touch_in_time?(touches, touches_s)} do
      {2, true} ->
        state
        |> Map.put(:action, :right_click)
        |> Map.put(:name, :init)

      {1, true} ->
        state
        |> Map.put(:name, :one_tap_and_one_touch_down)

      _ ->
        state
    end
    |> delete_touches(touches)
  end

  def handle_touch(%{name: :one_tap_and_one_touch_down} = state, "touchend", touches) do
    %{touches: touches_s} = state

    case {Enum.count(touches), touch_in_time?(touches, touches_s)} do
      {1, true} ->
        state
        |> Map.put(:action, :right_click)
        |> Map.put(:name, :init)

      _ ->
        state
        |> reset()
    end
    |> delete_touches(touches)
  end

  def handle_touch(%{name: name} = state, event, touches)
      when name in [:one_tap_dragged, :dragged] and event in ["touchend", "touchcancel"] do
    state
    |> Map.put(:action, :stop_dragging)
    |> Map.put(:name, :init)
    |> delete_touches(touches)
  end

  def handle_touch(state, "touchend", touches) do
    delete_touches(state, touches)
    |> reset()
  end

  def handle_touch(state, "touchcancel", touches) do
    delete_touches(state, touches)
    |> reset()
  end

  def handle_touch(%{name: :one_tap_dragging} = state, "touchmove", [_] = touches) do
    %{touches: touches_s} = state
    {dx, dy} = compute_avg_delta(touches, touches_s)

    state
    |> Map.put(:action, [:start_dragging, {:drag, dx, dy}])
    |> Map.put(:name, :one_tap_dragged)
    |> put_touches(touches)
  end

  def handle_touch(%{name: :one_tap_dragged} = state, "touchmove", [_] = touches) do
    %{touches: touches_s} = state
    {dx, dy} = compute_avg_delta(touches, touches_s)

    state
    |> Map.put(:action, {:drag, dx, dy})
    |> put_touches(touches)
  end

  def handle_touch(%{touches: touches_s} = state, "touchmove", touches)
      when map_size(touches_s) == 3 do
    {dx, dy} = compute_avg_delta(touches, touches_s)
    drag_action = {:drag, dx, dy}
    %{name: name} = state

    action =
      if name != :dragged do
        [:start_dragging, drag_action]
      else
        drag_action
      end

    state
    |> Map.put(:action, action)
    |> Map.put(:name, :dragged)
    |> put_touches(touches)
  end

  def handle_touch(state, "touchmove", touches) do
    %{touches: touches_s} = state
    {dx, dy} = compute_avg_delta(touches, touches_s)

    action_name =
      case Enum.count(touches_s) do
        2 -> :scroll
        _ -> :move
      end

    state
    |> Map.put(:action, {action_name, dx, dy})
    |> Map.put(:name, :moved)
    |> put_touches(touches)
  end

  def handle_info(state, action) do
    with %{waiting_for_timer: waiting_action} when waiting_action == action <- state do
      Map.put(state, :action, action)
      |> Map.put(:waiting_for_timer, false)
      |> Map.put(:name, :init)
    else
      _ -> state
    end
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

  defp touch_in_time?(touches, still_touches) do
    with dt when not is_nil(dt) <- compute_max_time_delta(touches, still_touches) do
      dt < @click_max_time
    else
      _ -> false
    end
  end

  defp compute_delta(touch, touches_p) do
    %{"id" => id, "x" => x, "y" => y} = touch
    %{"x" => x_p, "y" => y_p} = Map.get(touches_p, id) || touch
    {x - x_p, y - y_p}
  end

  defp compute_avg_delta([], _touches_p) do
    {0, 0}
  end

  defp compute_avg_delta(touches, touches_p) do
    {count, dx_sum, dy_sum} =
      Enum.reduce(touches, {0, 0, 0}, fn touch, {count, dx_sum, dy_sum} ->
        {dx, dy} = compute_delta(touch, touches_p)
        {count + 1, dx_sum + dx, dy_sum + dy}
      end)

    {Kernel.trunc(dx_sum / count), Kernel.trunc(dy_sum / count)}
  end

  defp put_touches(%{touches: touches_p} = state, touches) do
    Map.put(state, :touches, put_touches(touches_p, touches))
  end

  defp put_touches(touches_p, touches) do
    Enum.reduce(touches, touches_p, fn %{"id" => id} = touch, touches_p ->
      Map.put(touches_p, id, touch)
    end)
  end

  defp delete_touches(%{touches: touches_p} = state, touches) do
    Map.put(state, :touches, delete_touches(touches_p, touches))
  end

  defp delete_touches(touches_p, touches) do
    Enum.reduce(touches, touches_p, fn %{"id" => id}, touches_p ->
      Map.delete(touches_p, id)
    end)
  end
end
