defmodule Codenames.Repo.Migrations.CreateSlackTeams do
  use Ecto.Migration

  def change do
    create table(:slack_teams) do
      add :team_id, :string
      add :token, :string

      timestamps()
    end

    create index(:slack_teams, [:team_id], unique: true)
  end
end
