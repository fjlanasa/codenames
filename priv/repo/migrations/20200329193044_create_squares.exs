defmodule Codenames.Repo.Migrations.CreateSquares do
  use Ecto.Migration

  def change do
    create table(:squares) do
      add :word, :string
      add :type, :string
      add :picked, :boolean, default: false, null: false
      add :row, :string
      add :column, :string
      add :game, references(:games, on_delete: :nothing)

      timestamps()
    end

    create index(:squares, [:game])
  end
end
