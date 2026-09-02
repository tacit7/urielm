import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :urielm, Urielm.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "urielm_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: max(System.schedulers_online() * 2, 10),
  ownership_timeout: 600_000,
  queue_target: 5_000

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :urielm, UrielmWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "/MDHVV7gPgBIJ6ywVcNZfQ85uReZf08nz9lTFPxA3o/4ukozWcD5XFXIa/MRC2Nl",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Bypass rate limiting in tests
config :urielm, :rate_limit_bypass, true

# Keep upload tests isolated from Cloudflare R2.
config :urielm, :uploads,
  bucket: "test-bucket",
  public_url: "https://example.test",
  max_file_size: 10_485_760,
  storage_adapter: :noop
