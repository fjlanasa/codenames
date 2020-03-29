defmodule Codenames.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :channel, :string
      add :blue_player_id, references(:players, on_delete: :nothing)
      add :red_player_id, references(:players, on_delete: :nothing)

      timestamps()
    end

    create index(:games, [:blue_player_id])
    create index(:games, [:red_player_id])
  end
end
