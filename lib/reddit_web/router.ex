defmodule RedditWeb.Router do
  use RedditWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RedditWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RedditWeb do
    pipe_through :browser

    # Remove the page controller route and replace with our LiveView routes
    # get "/", PageController, :home

    # LiveView routes
    live "/", LinkListLive, :index

    # Add redirect for /links to the root path
    get "/links", RedirectController, :redirect_to_root
    live "/links", LinkListLive, :index
    live "/links/new", LinkSubmitLive, :new
    live "/links/:id/edit", LinkEditLive, :edit
    live "/links/:id", LinkDetailLive, :show

    # Topic management routes
    live "/topics", TopicListLive, :index
    live "/topics/new", TopicNewLive, :new
    live "/topics/:slug", TopicLinkListLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", RedditWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:reddit, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RedditWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
