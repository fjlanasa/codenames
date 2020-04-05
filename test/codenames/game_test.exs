defmodule Codenames.GameTest do
  use ExUnit.Case
  use Codenames.DataCase
  alias Codenames.{Repo, Game, Player, Square, Board}

  describe "database" do
    test "insert" do
      {:ok, player_1} = Repo.insert(%Player{channel: "slack", channel_id: "slack_player_1"})
      {:ok, player_2} = Repo.insert(%Player{channel: "slack", channel_id: "slack_player_2"})

      {:ok, game} =
        Repo.insert(
          Game.changeset(%Game{}, %{
            blue_player_id: player_1.id,
            red_player_id: player_2.id,
            channel: "slack",
            channel_id: "slack_channel_1"
          })
        )

      assert game.blue_player_id == player_1.id
      assert game.red_player_id == player_2.id
      assert game.channel == "slack"
      assert game.first == "BLUE"
      assert game.next == "BLUE"
    end
  end

  describe "new" do
    test "happy" do
      {:ok, player_1} = Repo.insert(%Player{channel: "slack", channel_id: "slack_player_1"})
      {:ok, player_2} = Repo.insert(%Player{channel: "slack", channel_id: "slack_player_2"})

      {:ok, game} = Game.new(player_1.id, player_2.id, "slack", "slack_channel_1")
      assert game.blue_player_id == player_1.id
      assert game.red_player_id == player_2.id
      assert game.channel == "slack"
      assert game.first == "BLUE"
      assert game.next == "BLUE"
      squares = Repo.all(Square)
      assert Kernel.length(squares) == 25
      dir = System.tmp_dir!()
      tmp_file = Path.join(dir, "#{game.id}.svg")
      File.write!(tmp_file, Board.build_public_board(squares))
      Mogrify.open(tmp_file) |> Mogrify.format("jpg") |> Mogrify.save(path: "temp.jpg")
    end

    test "sad" do
      {:error, err} = Game.new(nil, nil, nil, nil)
      refute err.valid?
    end
  end
end
