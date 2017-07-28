defmodule ShoppingCartWeb.Router do
  use ShoppingCartWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ShoppingCartWeb do
    pipe_through :api
  end
end
