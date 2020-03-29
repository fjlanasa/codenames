defmodule CodenamesWeb.PageController do
  use CodenamesWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
