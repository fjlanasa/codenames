defmodule Codenames.Repo.Migrations.AddGameContstraints do
  use Ecto.Migration

  def change do
    create constraint(:games, :blue_not_null, check: "blue_player_id IS NOT NULL")
    create constraint(:games, :red_not_null, check: "red_player_id IS NOT NULL")
  end
end
