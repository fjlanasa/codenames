defmodule Codenames.Repo.Migrations.AddFirstToGames do
  use Ecto.Migration

  def change do
    alter table("games") do
      add :first, :string, default: "BLUE"
    end

    create constraint("games", :valid_first, check: "first IN ('BLUE', 'RED')")
  end
end
