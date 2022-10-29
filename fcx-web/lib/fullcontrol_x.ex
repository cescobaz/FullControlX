defmodule FullControlX do
  require Logger

  @moduledoc """
  FullControlX keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias FullControlX.Driver

  def system_info() do
    Driver.system_info(Driver)
  end

  def mouse_move(dx, dy) do
    Driver.mouse_move(Driver, dx, dy)
  end

  def mouse_left_down() do
    Driver.mouse_left_down(Driver)
  end

  def mouse_left_up() do
    Driver.mouse_left_up(Driver)
  end

  def mouse_left_click() do
    Driver.mouse_left_click(Driver)
  end

  def mouse_right_click() do
    Driver.mouse_right_click(Driver)
  end

  def mouse_double_click() do
    Driver.mouse_double_click(Driver)
  end

  def mouse_scroll_wheel(dx, dy) do
    Driver.mouse_scroll_wheel(Driver, dx, dy)
  end

  def mouse_drag(dx, dy) do
    Driver.mouse_drag(Driver, dx, dy)
  end

  def keyboard_type_text(text) do
    Driver.keyboard_type_text(Driver, text)
  end

  def keyboard_type_symbol(symbol) do
    Driver.keyboard_type_symbol(Driver, symbol)
  end

  def apps_ui() do
    Driver.ui_apps(Driver)
  end

  def get_urls() do
    port =
      Application.get_env(:fullcontrol_x, FullControlXWeb.Endpoint)
      |> Keyword.get(:http)
      |> Keyword.get(:port)

    urls =
      with {:ok, ips} <- :inet.getif() do
        ips
        |> Enum.filter(fn
          {{first, _, _, _}, _, _} -> first != 127
          _ -> false
        end)
        |> Enum.map(fn {{ip1, ip2, ip3, ip4}, _, _} ->
          "http://#{ip1}.#{ip2}.#{ip3}.#{ip4}:#{port}"
        end)
      else
        error ->
          Logger.error(message: "unable to get host IPs", error: error)
          []
      end

    with {:ok, hostname} <- :inet.gethostname() do
      List.insert_at(urls, -1, "http://#{hostname}:#{port}")
    else
      error ->
        Logger.error(message: "unable to get hostname", error: error)
        urls
    end
  end

  def print_connection_qrcode() do
    urls = get_urls()

    urls
    |> Enum.each(&IO.puts/1)

    List.last(urls)
    |> EQRCode.encode()
    |> EQRCode.render()
  end
end
