defmodule Urielm.Repo do
  use Ecto.Repo,
    otp_app: :urielm,
    adapter: Ecto.Adapters.Postgres
end
