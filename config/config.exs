# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :review_room, :scopes,
  user: [
    default: true,
    module: ReviewRoom.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :binary_id,
    schema_table: :users,
    test_data_fixture: ReviewRoom.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :review_room,
  ecto_repos: [ReviewRoom.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

config :review_room, ReviewRoom.Snippets,
  buffer: [
    flush_count: 10,
    flush_idle_ms: 5_000,
    max_attempts: 3
  ],
  tag_catalog: [
    %{label: "Elixir", value: "elixir", color: "indigo"},
    %{label: "Phoenix", value: "phoenix", color: "orange"},
    %{label: "LiveView", value: "liveview", color: "purple"},
    %{label: "Ecto", value: "ecto", color: "teal"},
    %{label: "Testing", value: "testing", color: "emerald"},
    %{label: "Tooling", value: "tooling", color: "sky"}
  ]

# Configures the endpoint
config :review_room, ReviewRoomWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ReviewRoomWeb.ErrorHTML, json: ReviewRoomWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ReviewRoom.PubSub,
  live_view: [signing_salt: "boHwWnaY"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :review_room, ReviewRoom.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  review_room: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  review_room: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
