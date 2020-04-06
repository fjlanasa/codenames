defmodule CodenamesWeb.SlackController do
  use CodenamesWeb, :controller
  alias Codenames.{Game, Player, Square, Repo, Board}
  import Ecto.Query
  @subcommands ~w(new guess status pass quit add_player help)
  @teams ~w(BLUE RED)
  @columns ~w(A B C D E)
  @rows ~w(1 2 3 4 5)
  @player_id_regex ~r/^<@[\w]+|[\w]+>&/

  def handle_message(conn, params) do
    Task.start(fn ->
      do_handle_message(params)
    end)

    send_resp(conn, 200, "")
  end

  defp do_handle_message(
         %{
           "text" => text
         } = params
       ) do
    with {:ok, {subcommand, args}} <- parse_message(text),
         {:ok, clean_args} <- validate_message({subcommand, args}) do
      execute({subcommand, clean_args}, params)
    else
      err ->
        IO.inspect(err)
    end
  end

  @spec parse_message(String.t()) :: {:ok, {String.t(), [String.t()]}} | {:error, String.t()}
  defp parse_message(command) do
    [subcommand | arguments] =
      if String.length(command) > 0, do: String.split(command), else: [nil, []]

    case subcommand in @subcommands do
      true ->
        {:ok, {subcommand, arguments}}

      false ->
        {:error, "invalid subcommand"}
    end
  end

  defp validate_message({"new", args}) when length(args) >= 2 do
    [blue_player_id, red_player_id | tail] = args

    with true <-
           Enum.all?([blue_player_id, red_player_id], fn x ->
             String.match?(x, @player_id_regex)
           end),
         true <- Enum.empty?(tail) || String.upcase(List.first(tail)) in @teams do
      {:ok,
       Enum.map([blue_player_id, red_player_id], fn x ->
         String.split(x, "|") |> List.first() |> String.slice(2..-1)
       end) ++ if(Enum.empty?(tail), do: ["BLUE"], else: [String.upcase(List.first(tail))])}
    else
      _ ->
        {:error, "invalid arguments"}
    end
  end

  defp validate_message({"guess", args}) when Kernel.length(args) >= 1 do
    [guess | _] = args

    with 2 <- String.length(guess),
         true <-
           String.upcase(String.at(guess, 0)) in @columns and
             String.at(guess, 1) in @rows do
      {:ok, [String.upcase(guess)]}
    else
      _ ->
        {:error, "invalid arguments"}
    end
  end

  defp validate_message({"add_player", args}) when Kernel.length(args) >= 1 do
    [player_id | _] = args

    if String.match?(player_id, @player_id_regex) do
      {:ok, [String.split(player_id, "|") |> List.first() |> String.slice(1..-1)]}
    else
      {:error, "invalid arguments"}
    end
  end

  defp validate_message({"quit", _}), do: {:ok, []}

  defp validate_message({"status", _}), do: {:ok, []}

  defp validate_message({"pass", _}), do: {:ok, []}

  defp validate_message({"help", _}), do: {:ok, []}

  defp validate_message(_) do
    {:error, "invalid subcommandd"}
  end

  defp execute({"new", args}, %{"channel_id" => channel_id}) do
    [blue_player_id, red_player_id, first] = args
    {:ok, blue_player} = Player.find_or_create("slack", blue_player_id)
    {:ok, red_player} = Player.find_or_create("slack", red_player_id)

    with {:ok, game} <- Game.new(blue_player.id, red_player.id, "slack", nil, first),
         {:ok, res} <-
           CodenamesWeb.SlackClient.open_conversation([blue_player_id, red_player_id]),
         {:ok, _} <-
           CodenamesWeb.SlackClient.upload_file(
             gen_board_image(Board.build_key(Game.get_squares(game)), game.id).path,
             "Here is the key for game #{game.id}",
             Jason.decode!(res.body)["channel"]["id"]
           ),
         {:ok, res} <- CodenamesWeb.SlackClient.create_conversation("cdn-#{game.id}"),
         {:ok, _} <-
           Repo.update(
             Ecto.Changeset.change(game, channel_id: Jason.decode!(res.body)["channel"]["id"])
           ),
         {:ok, _} <-
           CodenamesWeb.SlackClient.join_conversation(channel_id),
         {:ok, _} <-
           CodenamesWeb.SlackClient.post_message(
             channel_id,
             "A new game is starting in <##{Jason.decode!(res.body)["channel"]["id"]}>"
           ) do
      gen_and_send_status(Repo.get!(Game, game.id))
    else
      {:error, err} ->
        IO.inspect(err)
    end
  end

  defp execute({"guess", args}, %{"channel_id" => channel_id, "user_id" => user_id}) do
    [guess] = args
    game = get_game(channel_id)
    player = Repo.one(from(Player, where: [channel_id: ^"#{user_id}"]))

    player_is_up = is_player_up(game, player)

    if not is_nil(game) and is_nil(game.winner) and player_is_up do
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

        status = Game.get_status(game)

        if not is_nil(status.winner) do
          game_update = Ecto.Changeset.change(game, winner: status.winner)

          Repo.update!(game_update)
        end

        if square.type != game.next do
          game_update =
            Ecto.Changeset.change(game, next: Game.get_opposite_team(game.next))

          Repo.update!(game_update)
        end

        send_status(status, Repo.get(Game, game.id))
      else
        send_help(channel_id)
      end
    else
      send_help(channel_id)
    end
  end

  defp execute({"pass", _args}, %{"channel_id" => channel_id, "user_id" => user_id}) do
    game = get_game(channel_id)
    player = get_player(user_id)

    if is_player_up(game, player) do
      game = Ecto.Changeset.change(game, next: Game.get_opposite_team(game.next))
      game = Repo.update!(game)
      gen_and_send_status(game)
    else
      send_help(channel_id)
    end
  end

  defp execute({"add_player", args}, %{"channel_id" => _channel_id}) do
    IO.inspect(args)
  end

  defp execute({"quit", _}, %{"channel_id" => channel_id}) do
    game = get_game(channel_id)

    case Repo.delete(game) do
      {:ok, _struct} ->
        CodenamesWeb.SlackClient.post_message(
          game.channel_id,
          "This game has been deleted. Archive this channel by typing `/archive`."
        )

      {:error, _changeset} ->
        send_help("DELETE ERR")
    end
  end

  defp execute({"status", _}, %{"channel_id" => channel_id}) do
    game = get_game(channel_id)

    if game do
      gen_and_send_status(game)
    else
      send_help(channel_id)
    end
  end

  defp execute({"help", _}, %{"channel_id" => channel_id}), do: send_help(channel_id)

  defp gen_and_send_status(game) do
    Game.get_status(game) |> send_status(game)
  end

  defp send_status(
         %{
           board_content: board_content,
           winner: winner
         },
         game
       ) do
    message =
      if not is_nil(winner) do
        "#{winner} wins!"
      else
        "#{game.next} is up!"
      end

    channel = game.channel_id
    file = gen_board_image(board_content, game.id)
    CodenamesWeb.SlackClient.upload_file(file.path, message, channel)
  end

  def gen_board_image(content, id) do
    dir = System.tmp_dir!()
    tmp_file = Path.join(dir, "#{id}.svg")
    File.write!(tmp_file, content)
    file = Mogrify.open(tmp_file) |> Mogrify.format("jpg") |> Mogrify.save()
    file
  end

  def send_help(channel_id) do
    IO.puts(channel_id)
  end

  defp get_game(channel_id) do
    Repo.one(from(Game, where: [channel: "slack", channel_id: ^channel_id]))
  end

  defp get_player(channel_id) do
    Repo.one(from(Player, where: [channel_id: ^"#{channel_id}"]))
  end

  defp is_player_up(game, player) do
    cond do
      not is_nil(player) and not is_nil(game) and game.blue_player_id == player.id and
          game.next == "BLUE" ->
        true

      not is_nil(player) and not is_nil(game) and game.red_player_id == player.id and
          game.next == "RED" ->
        true

      true ->
        false
    end
  end
end
