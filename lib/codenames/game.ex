defmodule Codenames.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :channel, :string
    field :blue_player_id, :id
    field :red_player_id, :id

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:channel])
    |> validate_required([:channel])
  end
end
