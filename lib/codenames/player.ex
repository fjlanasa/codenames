defmodule Codenames.Player do
  use Ecto.Schema
  import Ecto.Changeset

  schema "players" do
    field :channel, :string
    field :channel_id, :string

    timestamps()
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:channel_id, :channel])
    |> validate_required([:channel_id, :channel])
  end
end
