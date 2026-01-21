defmodule FullControlXWeb.Components do
  use FullControlXWeb, :component

  @doc """
  Renders a [Remix Icon](https://remixicon.com).

  You can customize the size and colors of the icons by
  setting width, height, and background color classes.

  ## Examples

      <.icon name="ri-github-fill" />
      <.icon name="ri-github" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-5"

  def icon(%{name: "ri-" <> _} = assigns) do
    ~H"""
    <i class={[@name, @class]} aria-hidden="true"></i>
    """
  end

  def header(assigns) do
    ~H"""
    <div class="flex justify-center py-2 px-4 border-b border-neutral-700">
      <h1 class="text-base font-semibold">{@title}</h1>
    </div>
    """
  end

  def switch(assigns) do
    ~H"""
    <label class="switch">
      <input type="checkbox" checked />
      <span class="slider"></span>
    </label>
    """
  end
end
