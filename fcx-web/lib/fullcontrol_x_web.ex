defmodule FullControlXWeb do
  require Logger

  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use FullControlXWeb, :controller
      use FullControlXWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def generate_qrcode_svg(conn, content) do
    hash =
      :crypto.hash(:sha256, content)
      |> Base.encode16()
      |> String.downcase()

    filename = "qrcode-#{hash}.svg"
    files_path = Application.get_env(:fullcontrol_x, :files_path) || "priv/static/assets"
    path = "#{files_path}/#{filename}"

    if not File.exists?(path) do
      svg =
        content
        |> EQRCode.encode()
        |> EQRCode.svg()

      case File.write(path, svg, [:binary]) do
        {:error, error} -> Logger.error(file_write: error)
        _ -> nil
      end
    end

    FullControlXWeb.Router.Helpers.static_path(conn, "/files/#{filename}")
  end

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def controller do
    quote do
      use Phoenix.Controller, namespace: FullControlXWeb

      import Plug.Conn
      import FullControlXWeb.Gettext
      alias FullControlXWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      import FullControlXWeb.Components

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {FullControlXWeb.LayoutView, :live},
        container: {:div, class: "h-full flex flex-col justify-between items-stretch"}

      import FullControlXWeb.Components

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import FullControlXWeb.Components

      unquote(view_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import FullControlXWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      import Phoenix.HTML
      import Phoenix.HTML.Form
      # use PhoenixHTMLHelpers

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.Component

      import FullControlXWeb.ErrorHelpers
      import FullControlXWeb.Gettext
      alias FullControlXWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
