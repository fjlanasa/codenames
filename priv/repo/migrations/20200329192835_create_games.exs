defmodule Codenames.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :channel, :string
      add :channel_id, :string
      add :blue_player_id, references(:players, on_delete: :nothing)
      add :red_player_id, references(:players, on_delete: :nothing)
      add :winner, :string
      add :first, :string, default: "BLUE"
      add :next, :string, default: "BLUE"

      timestamps()
    end

    create index(:games, [:blue_player_id])
    create index(:games, [:red_player_id])
    create index(:games, [:channel, :channel_id], unique: true)
    create constraint(:games, :channel_not_null, check: "channel IS NOT NULL")
    create constraint(:games, :channel_id_not_null, check: "channel_id IS NOT NULL")
    create constraint(:games, :blue_not_null, check: "blue_player_id IS NOT NULL")
    create constraint(:games, :red_not_null, check: "red_player_id IS NOT NULL")
    create constraint(:games, :must_be_red_or_blue, check: "winner IN ('RED', 'BLUE')")
    create constraint(:games, :valid_first, check: "first IN ('BLUE', 'RED')")
  end
end
