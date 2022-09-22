defmodule FullControlXWeb.MainLive do
  use FullControlXWeb, :live_view

  def mount(_params, _session, socket) do
    FullControlX.Driver.system_info(FullControlX.Driver)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>ciao</div>
    """
  end
end
