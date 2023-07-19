defmodule HtmlClientWeb.Router do
  use HtmlClientWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HtmlClientWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/hangman", HtmlClientWeb do
    pipe_through :browser

    get "/", HangmanController, :home
    post "/", HangmanController, :new
    put "/", HangmanController, :update

    get "/current", HangmanController, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", HtmlClientWeb do
  #   pipe_through :api
  # end
end
