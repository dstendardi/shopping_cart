defmodule AcmeWeb.Router do
  use AcmeWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", AcmeWeb do
    pipe_through :api
  end
end
