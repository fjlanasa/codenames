defmodule CodenamesWeb.Router do
  use CodenamesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CodenamesWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/slack", CodenamesWeb do
    pipe_through :api
    post "/", SlackController, :handle_message
    get "/auth", SlackController, :auth
  end

  # Other scopes may use custom stacks.
  # scope "/api", CodenamesWeb do
  #   pipe_through :api
  # end
end
