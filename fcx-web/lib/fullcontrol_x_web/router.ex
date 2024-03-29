defmodule FullControlXWeb.Router do
  use FullControlXWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {FullControlXWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", FullControlXWeb do
    pipe_through :browser

    live_session :live do
      live "/", TrackpadLive
      live "/info", InfoLive
      live "/keyboard", KeyboardLive
      live "/trackpad", TrackpadLive
      live "/tools", ToolsLive
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", FullControlXWeb do
  #   pipe_through :api
  # end
end
