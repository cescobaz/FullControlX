defmodule FullControlXWeb.ToolsLive do
  use FullControlXWeb, :live_view

  def mount(_params, _session, socket) do
    audio_buttons = [
      %{title: "Volume Down", value: "volumedown", icon: "ri-volume-down-line"},
      %{title: "Mute", value: "mute", icon: "ri-volume-mute-line"},
      %{title: "Volume Up", value: "volumeup", icon: "ri-volume-up-line"}
    ]

    media_buttons = [
      %{title: "Back", value: "back", icon: "ri-skip-back-line"},
      %{title: "Play/Pause", value: "playpause", icon: "ri-play-line"},
      %{title: "Forward", value: "forward", icon: "ri-skip-forward-line"}
    ]

    arrows_buttons = [
      %{title: "Left", value: "left", icon: "ri-arrow-left-line"},
      %{title: "Down", value: "down", icon: "ri-arrow-down-line"},
      %{title: "Up", value: "up", icon: "ri-arrow-up-line"},
      %{title: "Right", value: "right", icon: "ri-arrow-right-line"}
    ]

    brightness_buttons = [
      %{title: "Brightness Down", value: "brightnessdown", icon: "ri-sun-line"},
      %{title: "Brightness Up", value: "brightnessup", icon: "ri-sun-fill"}
    ]

    {:ok,
     socket
     |> assign(:header_title, "Tools")
     |> assign(:audio_buttons, audio_buttons)
     |> assign(:media_buttons, media_buttons)
     |> assign(:arrows_buttons, arrows_buttons)
     |> assign(:brightness_buttons, brightness_buttons)}
  end

  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col justify-end">
      <div class="overflow-scroll flex flex-col justify-start gap-6 p-4">
        <div class="flex justify-center gap-4">
          <%= for button <- @brightness_buttons do %>
            <._button title={button.title} value={button.value} icon={button.icon} />
          <% end %>
        </div>
        <div class="flex justify-center gap-4">
          <%= for button <- @arrows_buttons do %>
            <._button title={button.title} value={button.value} icon={button.icon} />
          <% end %>
        </div>
        <div class="flex justify-center gap-4">
          <%= for button <- @media_buttons do %>
            <._button title={button.title} value={button.value} icon={button.icon} />
          <% end %>
        </div>
        <div class="flex justify-center gap-4">
          <%= for button <- @audio_buttons do %>
            <._button title={button.title} value={button.value} icon={button.icon} />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def _button(assigns) do
    ~H"""
    <button phx-click="keyboard" value={@value} title={@title}>
      <.icon name={@icon} class="size-12" />
    </button>
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
