defmodule FullControlXWeb.InfoLive do
  use FullControlXWeb, :live_view

  def mount(_params, _session, socket) do
    info = FullControlX.system_info() || %{}
    urls = FullControlX.get_urls()
    url_in_qrcode = List.last(urls)
    qrcode_svg_url = FullControlXWeb.generate_qrcode_svg(socket, url_in_qrcode)

    {:ok,
     socket
     |> assign(:header_title, "Info")
     |> assign(:info, info)
     |> assign(:urls, urls)
     |> assign(:url_in_qrcode, url_in_qrcode)
     |> assign(:qrcode_svg_url, qrcode_svg_url)}
  end

  def render(assigns) do
    ~H"""
    <div class="m-auto flex flex-col gap-4 justify-start items-start p-4 max-w-xl">
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
        <h2>URLs</h2>
        <ul>
          <%= for url <- @urls do %>
            <li><a href={url} target="_blank"><%= url %></a></li>
          <% end %>
        </ul>
      </div>
      <div>
        <h2>QR code</h2>
        <p><%= @url_in_qrcode %></p>
        <img src={@qrcode_svg_url} />
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
