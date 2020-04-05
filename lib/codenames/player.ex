defmodule Codenames.Player do
  use Ecto.Schema
  import Ecto.Changeset
  alias Codenames.Repo

  schema "players" do
    field :channel, :string
    field :channel_id, :string

    timestamps()
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:channel_id, :channel])
    |> unique_constraint(:channel, name: :players_channel_channel_id_index)
    |> validate_required([:channel_id, :channel])
  end

  def find_or_create(channel, channel_id) do
    player = Repo.get_by(Codenames.Player, channel: channel, channel_id: channel_id)

    if not is_nil(player) do
      {:ok, player}
    else
      Repo.insert(
        Codenames.Player.changeset(%Codenames.Player{}, %{
          channel: channel,
          channel_id: channel_id
        })
      )
    end
  end
end
