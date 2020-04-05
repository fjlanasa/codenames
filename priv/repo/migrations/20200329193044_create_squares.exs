defmodule Codenames.Repo.Migrations.CreateSquares do
  use Ecto.Migration

  def change do
    create table(:squares) do
      add :word, :string
      add :type, :string
      add :picked, :boolean, default: false, null: false
      add :row, :string
      add :column, :string
      add :game, references(:games, on_delete: :delete_all)
      add :picked_by, :string

      timestamps()
    end

    create index(:squares, [:game])
    create index(:squares, [:game, :row, :column, :picked])
    create constraint(:squares, :valid_picked_by, check: "picked_by IN ('BLUE', 'RED')")

    create constraint(:squares, :valid_type,
             check: "picked_by IN ('BLUE', 'RED', 'ASSASSIN', 'NEUTRAL')"
           )
  end
end
