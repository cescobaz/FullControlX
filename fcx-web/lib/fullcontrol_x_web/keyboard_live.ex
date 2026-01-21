defmodule FullControlXWeb.KeyboardLive do
  use FullControlXWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:header_title, "Keyboard")
     |> assign(:form, to_form(%{"text" => "wee"}))}
  end

  def render(assigns) do
    ~H"""
    <div class="grow">
      <.form id="keyboard_textarea" for={@form} phx-change="change" phx-submit="submit">
        <div class="flex flex-col items-stretch gap-4 p-4">
          <textarea name="text" value={Map.get(@form, "text")} placeholder="Type something to send" />
          <input type="submit" value="Send" />
        </div>
      </.form>
    </div>
    """
  end

  def handle_event("change", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", %{"text" => text}, socket) do
    FullControlX.keyboard_type_text(text)
    {:noreply, socket}
  end
end
