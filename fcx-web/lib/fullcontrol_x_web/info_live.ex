defmodule FullControlXWeb.InfoLive do
  use FullControlXWeb, :live_view

  def mount(_params, _session, socket) do
    info = FullControlX.system_info() || %{}
    {:ok, assign(socket, :info, info)}
  end

  def render(assigns) do
    ~H"""
    <.header title="Info" />
    <div class="m-auto overflow-scroll flex flex-col gap-4 justify-center items-start h-full p-4 max-w-xl">
      <div>
        <h2>Host</h2>
        <div>
          <%= for {key, value} <- @info do %>
            <div>
              <%= "#{key}: #{value}" %>
            </div>
          <% end %>
        </div>
      </div>
      <div>
        <h2>FullControlX</h2>
        <p>FullControlX is the official Open Source "spinoff" of the commercial app <a href="https://fullcontrol.cescobaz.com" target="_blank">FullControl</a>.</p>
        <p>Developed and maintained by Francesco Burelli. More info at <a href="https://github.com/cescobaz/FullControlX" target="_blank">Github Project Homepage</a>.</p>
      </div>
    </div>
    """
  end
end
