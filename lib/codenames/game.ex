defmodule Codenames.Game do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Codenames.{Square, Words, Board, Repo}

  schema "games" do
    field :channel, :string
    field :channel_id, :string
    field :blue_player_id, :id
    field :red_player_id, :id
    field :first, :string, default: "BLUE"
    field :next, :string, default: "BLUE"
    field :winner, :string
    has_many :squares, Square, foreign_key: :game

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:blue_player_id, :red_player_id, :channel, :channel_id, :first, :next])
    |> unique_constraint(:channel, name: :games_channel_channel_id_index)
    |> validate_required([:channel, :first, :next])
    |> validate_inclusion(:first, ["BLUE", "RED"])
    |> validate_inclusion(:next, ["BLUE", "RED"])
  end

  def gen_squares(game_id, first) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    second = get_opposite_team(first)
    words = Words.get_words_for_game()

    types =
      Enum.shuffle(
        List.duplicate(first, 9) ++
          List.duplicate(second, 8) ++ List.duplicate("NEUTRAL", 7) ++ ["ASSASSIN"]
      )

    spaces =
      Enum.flat_map(["A", "B", "C", "D", "E"], fn col ->
        Enum.map(["1", "2", "3", "4", "5"], fn row -> {col, row} end)
      end)

    Enum.map(Enum.zip([words, types, spaces]), fn {word, type, {col, row}} ->
      %{
        word: word,
        type: type,
        column: col,
        row: row,
        game: game_id,
        inserted_at: now,
        updated_at: now
      }
    end)
  end

  @spec new(number(), number(), String.t(), String.t()) :: {:ok, __MODULE__} | {:error, any()}
  def new(blue_player_id, red_player_id, channel, channel_id, first \\ "BLUE") do
    with {:ok, game} <-
           Codenames.Repo.insert(
             changeset(%Codenames.Game{}, %{
               blue_player_id: blue_player_id,
               red_player_id: red_player_id,
               channel: channel,
               channel_id: channel_id,
               first: first,
               next: first
             })
           ),
         _ <-
           Repo.insert_all(Square, gen_squares(game.id, first)) do
      {:ok, game, get_status(game)}
    else
      {:error, err} ->
        {:error, err}
    end
  end

  def get_squares(game) do
    Repo.all(from(s in Square, where: s.game == ^game.id))
  end

  def execute_pass(game) do
    current_team = game.next
    game = Ecto.Changeset.change(game, next: get_opposite_team(game.next))
    game = Repo.update!(game)
    {:ok, game, get_status(game), "#{current_team} passes."}
  end

  def execute_guess(game, guess) do
    square =
      Repo.one(
        from(Square,
          where: [
            game: ^game.id,
            column: ^String.at(guess, 0),
            row: ^String.at(guess, 1),
            picked: false
          ]
        )
      )

    if square do
      square = Ecto.Changeset.change(square, picked: true, picked_by: game.next)
      square = Repo.update!(square)

      status = get_status(game)

      game =
        if not is_nil(status.winner),
          do: Repo.update!(Ecto.Changeset.change(game, winner: status.winner)),
          else: game

      message = "The guess is #{square.word}. "

      {game, message} =
        if square.type != game.next do
          {Repo.update!(Ecto.Changeset.change(game, next: get_opposite_team(game.next))),
           message <> "Incorrect! "}
        else
          {game, message <> "Correct! "}
        end

      {:ok, game, status, message}
    else
      {:error, "Not a valid guess."}
    end
  end

  def get_status(game) do
    first = game.first
    second = get_opposite_team(first)
    squares = get_squares(game)

    status =
      Enum.reduce(
        squares,
        %{
          first_count: 0,
          second_count: 0,
          picked_assassin: nil,
          board_content: "",
          available: []
        },
        fn x, acc ->
          %{
            available: if(x.picked, do: acc.available, else: acc.available ++ [x]),
            first_count:
              if(x.type == first and x.picked, do: acc.first_count + 1, else: acc.first_count),
            second_count:
              if(x.type == second and x.picked, do: acc.second_count + 1, else: acc.second_count),
            picked_assassin: if(x.type == "ASSASSIN", do: x.picked_by, else: acc.picked_assassin),
            board_content: acc.board_content <> Board.build_square(x)
          }
        end
      )

    winner =
      cond do
        not is_nil(status.picked_assassin) ->
          get_opposite_team(status.picked_assassin)

        status.picked_assassin == "BLUE" ->
          "RED"

        status.picked_assassin == "RED" ->
          "BLUE"

        status.first_count == 9 ->
          first

        status.second_count == 8 ->
          second

        true ->
          nil
      end

    status = Map.put(status, :winner, winner)
    %{status | board_content: Board.wrap_board_content(status.board_content)}
  end

  def get_opposite_team("BLUE"), do: "RED"
  def get_opposite_team("RED"), do: "BLUE"
end
