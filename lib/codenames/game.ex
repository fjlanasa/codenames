defmodule Codenames.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :channel, :string
    field :blue_player_id, :id
    field :red_player_id, :id
    field :first, :string
    field :next, :string

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:channel, :first, :next])
    |> validate_required([:channel, :first])
    |> validate_inclusion(:first, ["BLUE", "RED"])
    |> validate_inclusion(:next, ["BLUE", "RED"])
  end
end
