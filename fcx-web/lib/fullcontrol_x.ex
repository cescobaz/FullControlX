defmodule FullControlX do
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

  def mouse_left_click() do
    Driver.mouse_left_click(Driver)
  end

  def apps_ui() do
    Driver.ui_apps(Driver)
  end
end
