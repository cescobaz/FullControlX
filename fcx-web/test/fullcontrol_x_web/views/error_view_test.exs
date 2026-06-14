defmodule FullControlXWeb.ErrorViewTest do
  use FullControlXWeb.ConnCase, async: true

  # ErrorView has no templates, so it falls back to template_not_found/2,
  # which returns the status message for the requested template.
  test "renders the 404 status message" do
    assert FullControlXWeb.ErrorView.template_not_found("404.html", %{}) == "Not Found"
  end

  test "renders the 500 status message" do
    assert FullControlXWeb.ErrorView.template_not_found("500.html", %{}) ==
             "Internal Server Error"
  end
end
