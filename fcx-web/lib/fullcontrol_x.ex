defmodule FullControlX do
  @moduledoc """
  FullControlX keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def system_info() do
    FullControlX.Driver.system_info(FullControlX.Driver)
  end

  def apps_ui() do
    FullControlX.Driver.ui_apps(FullControlX.Driver)
  end
end
