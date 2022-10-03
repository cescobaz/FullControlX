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
end
