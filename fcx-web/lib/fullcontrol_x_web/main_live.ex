defmodule FullControlXWeb.MainLive do
  use FullControlXWeb, :live_view

  def mount(_params, _session, socket) do
    info = FullControlX.Driver.system_info(FullControlX.Driver)
    {:ok, assign(socket, :info, info)}
  end

  def render(assigns) do
    ~H"""
    <h1>System info</h1>
    <%= for {key, value} <- @info do %>
      <div>
        <%= "#{key}: #{value}" %>
      </div>
    <% end %>
    """
  end
end
