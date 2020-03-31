defmodule Codenames.Square do
  use Ecto.Schema
  import Ecto.Changeset

  schema "squares" do
    field :column, :string
    field :picked, :boolean, default: false
    field :row, :string
    field :type, :string
    field :word, :string
    field :game, :id
    field :picked_by, :string

    timestamps()
  end

  @doc false
  def changeset(square, attrs) do
    square
    |> cast(attrs, [:word, :type, :picked, :row, :column])
    |> validate_required([:word, :type, :picked, :row, :column])
    |> validate_inclusion(:column, ["A", "B", "C", "D", "E"])
    |> validate_inclusion(:row, ["1", "2", "3", "4", "5"])
    |> validate_inclusion(:picked_by, ["BLUE", "RED"])
  end
end
