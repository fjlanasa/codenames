defmodule Codenames.Square do
  use Ecto.Schema
  import Ecto.Changeset
  alias Codenames.Game

  schema "squares" do
    field :column, :string
    field :picked, :boolean, default: false
    field :row, :string
    field :type, :string
    field :word, :string
    field :picked_by, :string
    belongs_to :game_id, Game, foreign_key: :game

    timestamps()
  end

  @doc false
  def changeset(square, attrs) do
    square
    |> cast(attrs, [:word, :type, :picked, :row, :column, :game])
    |> validate_required([:word, :type, :picked, :row, :column, :game])
    |> validate_inclusion(:type, ["RED", "BLUE", "NEUTRAL", "ASSASSIN"])
    |> validate_inclusion(:column, ["A", "B", "C", "D", "E"])
    |> validate_inclusion(:row, ["1", "2", "3", "4", "5"])
    |> validate_inclusion(:picked_by, ["BLUE", "RED"])
  end
end
