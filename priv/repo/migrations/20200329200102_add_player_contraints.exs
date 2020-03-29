defmodule Codenames.Repo.Migrations.AddPlayerContraints do
  use Ecto.Migration

  def change do
    create constraint(:players, :channel_not_null, check: "channel IS NOT NULL")
    create constraint(:players, :channel_id_not_null, check: "channel_id IS NOT NULL")
    create index(:players, [:channel, :channel_id], unique: true)
  end
end
