defmodule ReviewRoomWeb.PageController do
  use ReviewRoomWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
