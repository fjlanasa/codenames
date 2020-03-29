# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :codenames,
  ecto_repos: [Codenames.Repo]

# Configures the endpoint
config :codenames, CodenamesWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "aNq3bo3hbPq+BF6M/c7phpF22uFU3s1/8afNmdub+86ywnkXhDokHdXy8i+VQV03",
  render_errors: [view: CodenamesWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Codenames.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "rTtbsYLI"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
