defmodule FullControlXWeb.ToolsLive do
  use FullControlXWeb, :live_view

  def mount(_params, _session, socket) do
    info = FullControlX.system_info() || %{}

    {:ok, assign(socket, :info, info)}
  end

  def render(assigns) do
    ~H"""
    <.header title="Tools" />
    <%= for {key, value} <- @info do %>
      <div>
        <%= "#{key}: #{value}" %>
      </div>
    <% end %>
    <div class="grow"></div>
    """
  end
end
