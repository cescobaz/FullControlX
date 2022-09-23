defmodule FullControlXWeb.Components do
  use FullControlXWeb, :component

  def header(assigns) do
    ~H"""
    <div class="flex justify-center py-2 px-4 border-b border-neutral-700">
      <h1 class="text-base font-semibold"><%= @title %></h1>
    </div>
    """
  end
end
