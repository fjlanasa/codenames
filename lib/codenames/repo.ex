defmodule Codenames.Repo do
  use Ecto.Repo,
    otp_app: :codenames,
    adapter: Ecto.Adapters.Postgres
end
