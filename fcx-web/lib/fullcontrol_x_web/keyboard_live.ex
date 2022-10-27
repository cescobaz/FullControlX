defmodule FullControlXWeb.KeyboardLive do
  use FullControlXWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.header title="Keyboard" />
    <div class="grow">
      <.form id="keyboard_textarea" for={:keyboard} phx-change="change" phx-submit="submit" let={f}>
        <div class="flex flex-col items-stretch gap-4 p-4">
          <%= textarea f, :text %> 
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
    FullControlX.keyboard_type(text)
    {:noreply, socket}
  end
end
