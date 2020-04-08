defmodule Codenames.Slack.Team do
  use Ecto.Schema
  import Ecto.Changeset

  schema "slack_teams" do
    field :team_id, :string
    field :token, :string

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:team_id, :token])
    |> validate_required([:team_id, :token])
    |> unique_constraint(:team_id)
  end
end
