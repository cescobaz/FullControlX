defmodule FullControlXWeb.ToolsLive do
  use FullControlXWeb, :live_view

  def mount(_params, _session, socket) do
    info = FullControlX.system_info() || %{}

    audio_buttons = [
      %{
        title: "Volume Down",
        value: "volumedown",
        src: Routes.static_path(socket, "/images/VolumeDown.png")
      },
      %{title: "Mute", value: "mute", src: Routes.static_path(socket, "/images/Mute.png")},
      %{
        title: "Volume Up",
        value: "volumeup",
        src: Routes.static_path(socket, "/images/VolumeUp.png")
      }
    ]

    media_buttons = [
      %{
        title: "Back",
        value: "back",
        src: Routes.static_path(socket, "/images/Back.png")
      },
      %{
        title: "Play/Pause",
        value: "playpause",
        src: Routes.static_path(socket, "/images/PlayPause.png")
      },
      %{
        title: "Forward",
        value: "forward",
        src: Routes.static_path(socket, "/images/Forward.png")
      }
    ]

    arrows_buttons = [
      %{
        title: "Left",
        value: "left",
        src: Routes.static_path(socket, "/images/LeftArrow.png")
      },
      %{
        title: "Down",
        value: "down",
        src: Routes.static_path(socket, "/images/DownArrow2.png")
      },
      %{
        title: "Up",
        value: "up",
        src: Routes.static_path(socket, "/images/UpArrow.png")
      },
      %{
        title: "Right",
        value: "right",
        src: Routes.static_path(socket, "/images/RightArrow.png")
      }
    ]

    brightness_buttons = [
      %{
        title: "Brightness Down",
        value: "brightnessdown",
        src: Routes.static_path(socket, "/images/BrightnessDown@2x.png")
      },
      %{
        title: "Brightness Up",
        value: "brightnessup",
        src: Routes.static_path(socket, "/images/BrightnessUp@2x.png")
      }
    ]

    {:ok,
     assign(socket, :info, info)
     |> assign(:audio_buttons, audio_buttons)
     |> assign(:media_buttons, media_buttons)
     |> assign(:arrows_buttons, arrows_buttons)
     |> assign(:brightness_buttons, brightness_buttons)}
  end

  def render(assigns) do
    ~H"""
    <.header title="Tools" />
    <div class="overflow-scroll">
      <div>
        <%= for {key, value} <- @info do %>
          <div>
            <%= "#{key}: #{value}" %>
          </div>
        <% end %>
      </div>
      <div class="flex flex-col justify-end gap-4 pb-4">
        <div class="flex justify-center gap-4">
          <%= for button <- @brightness_buttons do %>
            <._button title={button.title} value={button.value} src={button.src} />
          <% end %>
        </div>
        <div class="flex justify-center gap-4">
          <%= for button <- @arrows_buttons do %>
            <._button title={button.title} value={button.value} src={button.src} />
          <% end %>
        </div>
        <div class="flex justify-center gap-4">
          <%= for button <- @media_buttons do %>
            <._button title={button.title} value={button.value} src={button.src} />
          <% end %>
        </div>
        <div class="flex justify-center gap-4">
          <%= for button <- @audio_buttons do %>
            <._button title={button.title} value={button.value} src={button.src} />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def _button(assigns) do
    ~H"""
    <button phx-click="keyboard" value={@value} title={@title}>
      <img src={@src} />
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
