defmodule FullControlXWeb.PageControllerTest do
  use FullControlXWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "FullControlX"
  end
end
