# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :acme,
  ecto_repos: [Acme.Repo],
  generators: [binary_id: true],
  max_item_per_order: 50,
  max_quantity_per_item: 200

# Configures the endpoint
config :acme, AcmeWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "rpZh6HmM+AigDo1BwUVRiH+VEqYION2kEFqaUP2jri8VyvbeEWXzxa16cRam4zY9",
  render_errors: [view: AcmeWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Acme.PubSub,
           adapter: Phoenix.PubSub.PG2]


# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
