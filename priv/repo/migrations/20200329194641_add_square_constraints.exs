defmodule Codenames.Repo.Migrations.AddSquareConstraints do
  use Ecto.Migration

  def change do
    create index(:squares, [:game, :word, :column, :type, :row], unique: true)
    create constraint(:squares, :game_not_null, check: "game IS NOT NULL")
    create constraint(:squares, :word_not_null, check: "word IS NOT NULL")
    create constraint(:squares, :column_not_null, check: "'column' IS NOT NULL")
    create constraint(:squares, :row_not_null, check: "row IS NOT NULL")
    create constraint(:squares, :picked_not_null, check: "picked IS NOT NULL")
    create constraint(:squares, :valid_column, check: "'column' IN ('A', 'B', 'C', 'D', 'E')")
    create constraint(:squares, :valid_row, check: "row IN ('1', '2', '3', '4', '5')")
    create constraint(:squares, :valid_type, check: "type IN ('RED', 'BLUE', 'NEUTRAL', 'ASSASSIN')")
  end
end
