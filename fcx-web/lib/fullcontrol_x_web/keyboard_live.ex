defmodule FullControlXWeb.KeyboardLive do
  use FullControlXWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:header_title, "Keyboard")}
  end

  def render(assigns) do
    ~H"""
    <div class="grow">
      <.form id="keyboard_textarea" for={:keyboard} phx-change="change" phx-submit="submit" let={f}>
        <div class="flex flex-col items-stretch gap-4 p-4">
          <%= textarea f, :text, placeholder: "Type something to send" %> 
          <%= submit "Send" %>
        </div>
      </.form>
    </div>
    """
  end

  def handle_event("change", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", %{"keyboard" => %{"text" => text}}, socket) do
    FullControlX.keyboard_type_text(text)
    {:noreply, socket}
  end
end
