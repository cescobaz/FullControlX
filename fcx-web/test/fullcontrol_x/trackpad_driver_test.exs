defmodule FullControlX.TrackpadDriverTest do
  use ExUnit.Case, async: true
  alias FullControlX.TrackpadDriver

  defp assert_action(state, action) do
    assert %{action: ^action} = state
    state
  end

  test "Left click" do
    touch = %{"id" => 1, "ts" => 0, "x" => 100, "y" => 200}

    TrackpadDriver.init()
    |> TrackpadDriver.handle_touch("touchstart", [touch])
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchend", [Map.put(touch, "ts", 200)])
    |> assert_action({:set_timer, :left_click, 200})
    |> TrackpadDriver.handle_info(:left_click)
    |> assert_action(:left_click)
  end

  test "Slow single tap does nothing" do
    touch = %{"id" => 1, "ts" => 0, "x" => 100, "y" => 200}

    TrackpadDriver.init()
    |> TrackpadDriver.handle_touch("touchstart", [touch])
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchend", [Map.put(touch, "ts", 300)])
    |> assert_action(nil)
  end

  test "Double click" do
    touch = %{"id" => 1, "ts" => 0, "x" => 100, "y" => 200}
    touch_2 = %{"id" => 2, "ts" => 300, "x" => 100, "y" => 200}

    TrackpadDriver.init()
    |> TrackpadDriver.handle_touch("touchstart", [touch])
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchend", [Map.put(touch, "ts", 200)])
    |> assert_action({:set_timer, :left_click, 200})
    |> TrackpadDriver.handle_touch("touchstart", [touch_2])
    |> assert_action({:cancel_timer, :left_click})
    |> TrackpadDriver.handle_touch("touchend", [Map.put(touch_2, "ts", 400)])
    |> assert_action(:double_click)
  end

  test "Slow double tap does two left click" do
    touch = %{"id" => 1, "ts" => 0, "x" => 100, "y" => 200}
    touch_2 = %{"id" => 2, "ts" => 500, "x" => 100, "y" => 200}

    TrackpadDriver.init()
    |> TrackpadDriver.handle_touch("touchstart", [touch])
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchend", [Map.put(touch, "ts", 200)])
    |> assert_action({:set_timer, :left_click, 200})
    |> TrackpadDriver.handle_info(:left_click)
    |> assert_action(:left_click)
    |> TrackpadDriver.handle_touch("touchstart", [touch_2])
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchend", [Map.put(touch_2, "ts", 550)])
    |> assert_action({:set_timer, :left_click, 200})
    |> TrackpadDriver.handle_info(:left_click)
    |> assert_action(:left_click)
  end

  test "Two fingers tap does right click" do
    touches_start = [
      %{"id" => 1, "ts" => 0, "x" => 100, "y" => 200},
      %{"id" => 2, "ts" => 0, "x" => 100, "y" => 200}
    ]

    touches_end = Enum.map(touches_start, fn touch -> Map.put(touch, "ts", 100) end)

    TrackpadDriver.init()
    |> TrackpadDriver.handle_touch("touchstart", touches_start)
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchend", touches_end)
    |> assert_action(:right_click)
  end

  test "Two fingers tap (async start) does right click" do
    touches_start_1 = %{"id" => 1, "ts" => 0, "x" => 100, "y" => 200}
    touches_start_2 = %{"id" => 2, "ts" => 50, "x" => 100, "y" => 200}

    touches_end =
      Enum.map([touches_start_1, touches_start_2], fn touch -> Map.put(touch, "ts", 100) end)

    TrackpadDriver.init()
    |> TrackpadDriver.handle_touch("touchstart", [touches_start_1])
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchstart", [touches_start_2])
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchend", touches_end)
    |> assert_action(:right_click)
  end

  test "Two fingers tap (async end) does right click" do
    touches_start = [
      %{"id" => 1, "ts" => 0, "x" => 100, "y" => 200},
      %{"id" => 2, "ts" => 0, "x" => 100, "y" => 200}
    ]

    touches_end_1 = Map.put(List.first(touches_start), "ts", 100)
    touches_end_2 = Map.put(List.last(touches_start), "ts", 150)

    TrackpadDriver.init()
    |> TrackpadDriver.handle_touch("touchstart", touches_start)
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchend", [touches_end_1])
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchend", [touches_end_2])
    |> assert_action(:right_click)
  end

  defp generate_moving_touch(id, ts) do
    state = %{"id" => id, "x" => 100, "y" => 200, "ts" => ts, "touches" => []}

    Enum.reduce(
      1..20,
      state,
      fn _i, state ->
        state
        |> Map.update!("touches", fn touches ->
          List.insert_at(touches, -1, Map.delete(state, "touches"))
        end)
        |> Map.update!("x", fn x -> x + 10 end)
        |> Map.update!("y", fn y -> y + 15 end)
        |> Map.update!("ts", fn ts -> ts + 50 end)
      end
    )
    |> Map.get("touches")
  end

  defp only_move(state, touches) do
    Enum.reduce(touches, state, fn touch, state ->
      state
      |> TrackpadDriver.handle_touch("touchmove", [touch])
      |> assert_action({:move, 10, 15})
    end)
  end

  defp move_test(state, id, ts) do
    touches = generate_moving_touch(id, ts)

    {touch_start, touches} = List.pop_at(touches, 0)
    {touch_end, touches} = List.pop_at(touches, -1)

    state
    |> TrackpadDriver.handle_touch("touchstart", [touch_start])
    |> assert_action(nil)
    |> only_move(touches)
    |> TrackpadDriver.handle_touch("touchend", [touch_end])
    |> assert_action(nil)
  end

  test "Move" do
    TrackpadDriver.init()
    |> move_test(1, 0)
  end
end
