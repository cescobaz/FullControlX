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

  def mouse_right_click() do
    Driver.mouse_right_click(Driver)
  end

  def mouse_double_click() do
    Driver.mouse_double_click(Driver)
  end

  def mouse_scroll_wheel(dx, dy) do
    Driver.mouse_scroll_wheel(Driver, dx, dy)
  end

  def apps_ui() do
    Driver.ui_apps(Driver)
  end
end
