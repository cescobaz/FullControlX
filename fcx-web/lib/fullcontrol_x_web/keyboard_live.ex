defmodule FullControlXWeb.KeyboardLive do
  use FullControlXWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.header title="Keyboard" />
    <div class="grow">
      <.form for={:keyboard} phx-change="change" phx-submit="submit" let={f}>
       <%= textarea f, :text %> 
       <%= submit "Send" %>
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
