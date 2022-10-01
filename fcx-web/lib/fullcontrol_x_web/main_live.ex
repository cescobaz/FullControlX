defmodule FullControlXWeb.MainLive do
  use FullControlXWeb, :live_view

  def mount(_params, _session, socket) do
    info = FullControlX.system_info()
    FullControlX.Driver.apps_observe(FullControlX.Driver)
    apps = FullControlX.apps_ui()

    {:ok,
     assign(socket, :info, info)
     |> assign(:apps, apps)
     |> assign(:touches, %{})}
  end

  def render(assigns) do
    ~H"""
    <.header title="FullControlX" />
    <%= for {key, value} <- @info do %>
      <div>
        <%= "#{key}: #{value}" %>
      </div>
    <% end %>
    <div id="trackpad" class="relative bg-green-800 grow" phx-touchstart="touchstart" phx-touchmove="touchmove" phx-touchend="touchend" phx-touchcancel="touchcancel" phx-hook="Trackpad">
      <h2>Trackpad</h2>
      <p>Fingers <%= Enum.count(@touches) %></p>
      <%= for {t_id, touch} <- @touches do %>
        <div
        id={"touch_#{t_id}"}
        class="absolute rounded-full w-28 h-28 bg-blue-900"
        style={"left: #{touch["x"]}px; top: #{touch["y"]}px;"}>
        </div>
      <% end %>
      
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

  def handle_event(event, params, socket) do
    IO.inspect(event: event, params: params)

    %{touches: touches_p} = socket.assigns
    touches = Map.get(params, "touches") || []
    IO.inspect(stored_touches_count: Enum.count(touches_p))

    socket =
      case {event, touches} do
        {"touchstart", touches} ->
          Enum.reduce(touches, socket, fn %{"id" => id} = touch, socket ->
            assign(socket, :touches, Map.put(touches_p, id, touch))
          end)

        {"touchend", touches} ->
          Enum.reduce(touches, socket, fn %{"id" => id}, socket ->
            assign(socket, :touches, Map.delete(touches_p, id))
          end)

        {"touchcancel", touches} ->
          Enum.reduce(touches, socket, fn %{"id" => id}, socket ->
            assign(socket, :touches, Map.delete(touches_p, id))
          end)

        {"touchmove", touches} ->
          {dx, dy} = compute_max_delta(touches, touches_p)
          IO.inspect(dx: dx, dy: dy)

          case Enum.count(touches_p) do
            1 ->
              FullControlX.mouse_move(dx, dy)

            _ ->
              IO.inspect("ignore")
          end

          Enum.reduce(touches, socket, fn %{"id" => id} = touch, socket ->
            assign(socket, :touches, Map.put(touches_p, id, touch))
          end)

        _ ->
          socket
      end

    {:noreply, socket}
  end
end
