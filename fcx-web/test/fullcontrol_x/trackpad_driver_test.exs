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

  test "Double click with timer cancellation fail" do
    touch = %{"id" => 1, "ts" => 0, "x" => 100, "y" => 200}
    touch_2 = %{"id" => 2, "ts" => 300, "x" => 100, "y" => 200}

    TrackpadDriver.init()
    |> TrackpadDriver.handle_touch("touchstart", [touch])
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchend", [Map.put(touch, "ts", 200)])
    |> assert_action({:set_timer, :left_click, 200})
    |> TrackpadDriver.handle_touch("touchstart", [touch_2])
    |> assert_action({:cancel_timer, :left_click})
    |> TrackpadDriver.handle_info(:left_click)
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

  defp move_test(state, id, ts) do
    state
    |> TrackpadDriver.handle_touch("touchstart", [%{"id" => id, "x" => 0, "y" => 0, "ts" => ts}])
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchmove", [
      %{"id" => id, "x" => 10, "y" => 40, "ts" => ts + 20}
    ])
    |> assert_action({:move, 10, 40})
    |> TrackpadDriver.handle_touch("touchmove", [
      %{"id" => id, "x" => 5, "y" => 100, "ts" => ts + 40}
    ])
    |> assert_action({:move, -5, 60})
    |> TrackpadDriver.handle_touch("touchend", [
      %{"id" => id, "x" => 10, "y" => 102, "ts" => ts + 400}
    ])
    |> assert_action(nil)
  end

  test "Move" do
    TrackpadDriver.init()
    |> move_test(1, 0)
  end

  defp scroll_test(state, id_1, id_2, ts) do
    state
    |> TrackpadDriver.handle_touch("touchstart", [
      %{"id" => id_1, "x" => 0, "y" => 0, "ts" => ts + 0},
      %{"id" => id_2, "x" => 10, "y" => 0, "ts" => ts + 0}
    ])
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchmove", [
      %{"id" => id_1, "x" => 0, "y" => 30, "ts" => ts + 20},
      %{"id" => id_2, "x" => 10, "y" => 30, "ts" => ts + 20}
    ])
    |> assert_action({:scroll, 0, 30})
    |> TrackpadDriver.handle_touch("touchmove", [
      %{"id" => id_1, "x" => 10, "y" => 50, "ts" => ts + 60},
      %{"id" => id_2, "x" => 10, "y" => 50, "ts" => ts + 60}
    ])
    |> assert_action({:scroll, 5, 20})
    |> TrackpadDriver.handle_touch("touchend", [
      %{"id" => id_1, "x" => 10, "y" => 50, "ts" => ts + 70},
      %{"id" => id_2, "x" => 10, "y" => 50, "ts" => ts + 70}
    ])
    |> assert_action(nil)
  end

  test "Scroll" do
    TrackpadDriver.init()
    |> scroll_test(1, 2, 0)
  end

  test "Scroll with one finger fixed" do
    TrackpadDriver.init()
    |> TrackpadDriver.handle_touch("touchstart", [
      %{"id" => 1, "x" => 0, "y" => 0, "ts" => 0},
      %{"id" => 2, "x" => 10, "y" => 1, "ts" => 0}
    ])
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchmove", [
      %{"id" => 1, "x" => 10, "y" => 30, "ts" => 20}
    ])
    |> assert_action({:scroll, 10, 30})
    |> TrackpadDriver.handle_touch("touchmove", [
      %{"id" => 1, "x" => 20, "y" => 40, "ts" => 40}
    ])
    |> assert_action({:scroll, 10, 10})
    |> TrackpadDriver.handle_touch("touchmove", [
      %{"id" => 2, "x" => 0, "y" => 40, "ts" => 200}
    ])
    |> assert_action({:scroll, -10, 39})
    |> TrackpadDriver.handle_touch("touchend", [
      %{"id" => 1, "x" => 20, "y" => 40, "ts" => 300},
      %{"id" => 2, "x" => 0, "y" => 40, "ts" => 300}
    ])
  end

  defp drag_with_one_finger_test(state, id, ts) do
    state
    |> TrackpadDriver.handle_touch("touchstart", [
      %{"id" => id, "x" => 100, "y" => 350, "ts" => ts + 0}
    ])
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchend", [
      %{"id" => id, "x" => 100, "y" => 350, "ts" => ts + 20}
    ])
    |> assert_action({:set_timer, :left_click, 200})
    |> TrackpadDriver.handle_touch("touchstart", [
      %{"id" => id, "x" => 150, "y" => 350, "ts" => ts + 90}
    ])
    |> assert_action({:cancel_timer, :left_click})
    |> TrackpadDriver.handle_touch("touchmove", [
      %{"id" => id, "x" => 200, "y" => 400, "ts" => ts + 800}
    ])
    |> assert_action([:start_dragging, {:drag, 50, 50}])
    |> TrackpadDriver.handle_touch("touchmove", [
      %{"id" => id, "x" => 100, "y" => 530, "ts" => ts + 900}
    ])
    |> assert_action({:drag, -100, 130})
    |> TrackpadDriver.handle_touch("touchend", [
      %{"id" => id, "x" => 100, "y" => 530, "ts" => ts + 950}
    ])
    |> assert_action(:stop_dragging)
  end

  test "Drag with one finger" do
    TrackpadDriver.init()
    |> drag_with_one_finger_test(1, 0)
  end

  defp drag_with_three_fingers(state, id_1, id_2, id_3, ts) do
    state
    |> TrackpadDriver.handle_touch("touchstart", [
      %{"id" => id_1, "x" => 0, "y" => 0, "ts" => ts}
    ])
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchstart", [
      %{"id" => id_2, "x" => 10, "y" => 20, "ts" => ts + 10}
    ])
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchstart", [
      %{"id" => id_3, "x" => 50, "y" => 0, "ts" => ts + 15}
    ])
    |> assert_action(nil)
    |> TrackpadDriver.handle_touch("touchmove", [
      %{"id" => id_1, "x" => 50, "y" => -40, "ts" => ts + 30},
      %{"id" => id_2, "x" => 60, "y" => -20, "ts" => ts + 30},
      %{"id" => id_3, "x" => 100, "y" => -40, "ts" => ts + 30}
    ])
    |> assert_action([:start_dragging, {:drag, 50, -40}])
    |> TrackpadDriver.handle_touch("touchmove", [
      %{"id" => id_1, "x" => 50, "y" => -30, "ts" => ts + 60}
    ])
    |> assert_action({:drag, 0, 10})
    |> TrackpadDriver.handle_touch("touchend", [
      %{"id" => id_1, "x" => 50, "y" => -30, "ts" => ts + 70},
      %{"id" => id_2, "x" => 60, "y" => -20, "ts" => ts + 70},
      %{"id" => id_3, "x" => 100, "y" => -40, "ts" => ts + 70}
    ])
    |> assert_action(:stop_dragging)
  end

  test "Drag with three fingers" do
    TrackpadDriver.init()
    |> drag_with_three_fingers(1, 2, 3, 0)
  end
end
