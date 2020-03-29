defmodule Codenames.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :channel_id, :string
      add :channel, :string

      timestamps()
    end

  end
end
