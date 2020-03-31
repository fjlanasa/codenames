defmodule Codenames.Repo.Migrations.AddTurnAndPickedByRemoveWinner do
  use Ecto.Migration

  def change do
    alter table("games") do
      add :next, :string, default: "BLUE"
      remove :winner
    end

    alter table("squares") do
      add :picked_by, :string
    end

    create constraint("games", :valid_next, check: "next IS NOT NULL AND next IN ('BLUE', 'RED')")
    create constraint("squares", :valid_picked_by, check: "picked_by IN ('BLUE', 'RED')")
  end
end
