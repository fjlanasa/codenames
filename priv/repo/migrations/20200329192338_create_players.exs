defmodule Codenames.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :channel_id, :string
      add :channel, :string

      timestamps()
    end

    create constraint(:players, :channel_not_null, check: "channel IS NOT NULL")
    create constraint(:players, :channel_id_not_null, check: "channel_id IS NOT NULL")
    create index(:players, [:channel, :channel_id], unique: true)
  end
end
