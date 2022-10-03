defmodule FullControlX.TrackpadDriver do
  @click_max_time 250

  def init() do
    %{
      touches: %{},
      touches_down: [],
      name: :init,
      action: nil
    }
  end

  def handle_touch(state, "touchstart", touches) do
    %{name: name, touches: touches_s} = state

    case name do
      :init ->
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

      :will_left_click ->
        case Enum.count(touches) do
          1 ->
            state
            |> Map.put(:action, {:cancel_timer, :left_click})
            |> Map.put(:name, :one_tap_dragging)

          _ ->
            state
        end

      _ ->
        state
    end
    |> Map.put(:touches, put_touches(touches_s, touches))
  end

  def handle_touch(state, "touchend", touches) do
    %{name: name, touches: touches_s} = state

    case name do
      :one_touch_down ->
        if touch_in_time?(touches, touches_s) do
          state
          |> Map.put(:action, {:set_timer, :left_click, 200})
          |> Map.put(:name, :will_left_click)
        else
          state
        end

      :one_tap_dragging ->
        if touch_in_time?(touches, touches_s) do
          state
          |> Map.put(:action, :double_click)
          |> Map.put(:name, :init)
        else
          state
        end

      :two_touches_down ->
        if Enum.count(touches) == 2 and touch_in_time?(touches, touches_s) do
          state
          |> Map.put(:action, :right_click)
          |> Map.put(:name, :init)
        else
          state
        end

      _ ->
        state
    end
    |> Map.put(:touches, delete_touches(touches_s, touches))
  end

  def handle_touch(state, "touchcancel", touches) do
    %{touches: touches_s} = state

    state
    |> Map.put(:touches, delete_touches(touches_s, touches))
  end

  def handle_touch(state, "touchmove", _touches) do
    state
  end

  def handle_info(state, action) do
    Map.put(state, :action, action)
    |> Map.put(:name, :init)
  end

  def cancel_timer(state) do
    with %{timer: timer} when not is_nil(timer) <- state do
      Process.cancel_timer(timer)
      Map.put(state, :timer, nil)
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

  def touches_close?(touch_a, touch_b) do
    %{"x" => x_a, "y" => y_a} = touch_a
    %{"x" => x_b, "y" => y_b} = touch_b
    :math.sqrt(:math.pow(x_b - x_a, 2) + :math.pow(y_b - y_a, 2)) < 10
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
end
