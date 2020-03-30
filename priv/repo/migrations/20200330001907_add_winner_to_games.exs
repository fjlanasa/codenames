defmodule Codenames.Repo.Migrations.AddWinnerToGames do
  use Ecto.Migration

  def change do
    alter table("games") do
      add :winner, :string
    end

    create constraint(:games, :must_be_red_or_blue, check: "winner IN ('RED', 'BLUE')")
  end
end
