defmodule CodenamesWeb.SlackController do
  use CodenamesWeb, :controller
  alias Codenames.{Game, Player, Square, Repo, Board, Slack}
  alias CodenamesWeb.SlackClient
  import Ecto.Query
  @subcommands ~w(new guess status pass quit add_player help)
  @teams ~w(BLUE RED)
  @columns ~w(A B C D E)
  @rows ~w(1 2 3 4 5)
  @player_id_regex ~r/^<@[\w]+|[\w]+>&/
  @salt System.get_env("SALT", "salt")

  def auth(conn, %{"code" => code}) do
    with {:ok,
          %{
            body: %{
              "access_token" => token,
              "team" => %{
                "id" => team_id
              }
            }
          }} <- SlackClient.get_oauth_access(code),
         {:ok, _} <-
           Repo.insert(
             Slack.Team.changeset(%Slack.Team{}, %{
               team_id: team_id,
               token: Phoenix.Token.encrypt(CodenamesWeb.Endpoint, @salt, token)
             })
           ) do
      send_resp(conn, 200, "All set! Type \"/cdnm help\" in Slack for more help.")
    else
      {:error,
       %{
         errors: [
           team_id:
             {"has already been taken",
              [constraint: :unique, constraint_name: "slack_teams_team_id_index"]}
         ]
       }} ->
        send_resp(conn, 400, "Your team has already installed this app.")

      err ->
        IO.inspect(err)
        send_resp(conn, 400, "Something went wrong.")
    end
  end

  def handle_message(conn, %{"team_id" => team_id} = params) do
    Task.start(fn ->
      case get_team_token(team_id) do
        {:ok, token} ->
          do_handle_message(params, token)

        _ ->
          IO.puts("No auth token")
      end
    end)

    json(conn, %{text: "", response_type: "in_channel"})
  end

  def actions(conn, %{"team_id" => team_id} = params) do
    case get_team_token(team_id) do
      {:ok, token} ->
        IO.inspect(params)
        handle_actions(params, token)

      _ ->
        IO.puts("No auth token")
    end

    send_resp(conn, 200, "")
  end

  def handle_actions(
        %{
          channel: %{
            id: channel_id
          },
          user: %{
            user_id: user_id
          },
          actions: [
            %{
              value: "pass",
              type: "button"
            }
          ]
        },
        token
      ) do
    do_execute_pass(channel_id, user_id, token)
  end

  def handle_actions(
        %{
          user: %{
            user_id: user_id
          },
          channel: %{
            id: channel_id
          },
          actions: [
            %{
              value: value
            }
          ]
        },
        token
      ) do
    game = get_game(channel_id)
    do_execute_guess(game, value, user_id, token)
  end

  defp do_handle_message(
         %{
           "text" => text,
           "channel_id" => channel_id,
           "user_id" => user_id
         } = params,
         token
       ) do
    with {:ok, {subcommand, args}} <- parse_message(text),
         {:ok, clean_args} <- validate_message({subcommand, args}),
         {:ok, execute({subcommand, clean_args}, params, token)} do
      :ok
    else
      err ->
        IO.inspect(err)
        send_error_message(token, channel_id, user_id, err)
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
        {:error, "Invalid command. Type `/cdnm help` for help."}
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
        {:error, "Invalid command. Type `/cdnm help` for help."}
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
        {:error, "Invalid command. Type `/cdnm help` for help."}
    end
  end

  defp validate_message({"add_player", args}) when Kernel.length(args) >= 1 do
    [player_id | _] = args

    if String.match?(player_id, @player_id_regex) do
      {:ok, [String.split(player_id, "|") |> List.first() |> String.slice(1..-1)]}
    else
      {:error, "Invalid command. Type `/cdnm help` for help."}
    end
  end

  defp validate_message({"quit", _}), do: {:ok, []}

  defp validate_message({"status", _}), do: {:ok, []}

  defp validate_message({"pass", _}), do: {:ok, []}

  defp validate_message({"help", _}), do: {:ok, []}

  defp validate_message(_) do
    {:error, "Invalid command. Type `/cdnm help` for help."}
  end

  @spec execute({String.t(), [String.t()]}, any(), String.t()) ::
          {:error, HTTPoison.Error.t()}
          | {:ok,
             %{
               :__struct__ => HTTPoison.AsyncResponse | HTTPoison.Response,
               optional(:body) => any,
               optional(:headers) => [any],
               optional(:id) => reference,
               optional(:request) => HTTPoison.Request.t(),
               optional(:request_url) => any,
               optional(:status_code) => integer
             }}
  defp execute(
         {"new", args},
         %{
           "channel_id" => channel_id,
           "user_id" => user_id,
           "response_url" => response_url
         },
         token
       ) do
    [blue_player_id, red_player_id, first] = args
    {:ok, blue_player} = Player.find_or_create("slack", blue_player_id)
    {:ok, red_player} = Player.find_or_create("slack", red_player_id)

    with {:ok, game} <- Game.new(blue_player.id, red_player.id, "slack", nil, first),
         {:ok,
          %HTTPoison.Response{body: %{"ok" => true, "channel" => %{"id" => private_channel_id}}}} <-
           SlackClient.open_conversation([blue_player_id, red_player_id], token),
         {:ok,
          %HTTPoison.Response{
            body: %{"ok" => true, "channel" => %{"id" => public_channel_id}}
          }} <-
           SlackClient.create_conversation(get_game_channel_name(game), token),
         {:ok, %HTTPoison.Response{body: %{"ok" => true}}} <-
           SlackClient.upload_file(
             Board.gen_board_image(Board.build_key(Game.get_squares(game)), game.id).path,
             "Here is the key for the game in <##{public_channel_id}>",
             private_channel_id,
             token
           ),
         {:ok, _} <-
           Repo.update(Ecto.Changeset.change(game, channel_id: public_channel_id)),
         {:ok, %HTTPoison.Response{body: %{"ok" => true}}} <-
           SlackClient.post(
             response_url,
             Jason.encode!(%{
               "text" => "A new game is starting in <##{public_channel_id}>",
               "response_type" => "in_channel"
             }),
             SlackClient.build_header(token)
           ),
         {:ok, %HTTPoison.Response{body: %{"ok" => true}}} do
      get_and_send_status(
        token,
        Repo.get!(Game, game.id),
        " use `/cdnm guess [SPACE] to enter a guess.",
        "AFTER"
      )
    else
      err ->
        IO.inspect(err)
        send_error_message(channel_id, user_id, err)
    end
  end

  defp execute({"guess", args}, %{"channel_id" => channel_id, "user_id" => user_id}, token) do
    [guess] = args
    game = get_game(channel_id)

    do_execute_guess(game, guess, user_id, token)
  end

  defp execute({"pass", _args}, %{"channel_id" => channel_id, "user_id" => user_id}, token) do
    do_execute_pass(channel_id, user_id, token)
  end

  defp execute({"add_player", _args}, %{"channel_id" => channel_id, "user_id" => user_id}, token) do
    send_error_message(token, channel_id, user_id)
  end

  defp execute({"quit", _}, %{"channel_id" => channel_id, "user_id" => user_id}, token) do
    game = get_game(channel_id)

    case Repo.delete(game) do
      {:ok, _struct} ->
        SlackClient.post_message(
          game.channel_id,
          "This game has been deleted. Archive this channel by typing `/archive`.",
          token
        )

      {:error, _changeset} ->
        send_error_message(token, channel_id, user_id)
    end
  end

  defp execute({"status", _}, %{"channel_id" => channel_id, "user_id" => user_id}, token) do
    game = get_game(channel_id)

    if game do
      get_and_send_status(token, game)
    else
      send_error_message(token, channel_id, user_id)
    end
  end

  defp execute(
         {"help", _},
         %{"response_url" => response_url},
         token
       ),
       do: SlackClient.send_help(response_url, token)

  defp get_and_send_status(token, game, message \\ "", message_placement \\ "BEFORE") do
    status = Game.get_status(game)
    send_status(token, status, game, message, message_placement)
  end

  defp send_status(
         token,
         %{
           board_content: board_content,
           winner: winner
         } = status,
         game,
         message,
         message_placement \\ "BEFORE"
       ) do
    message =
      if message_placement == "BEFORE" do
        message <> " " <> status_content(game, winner)
      else
        status_content(game, winner) <> " " <> message
      end

    message = message <> "\n\nType `/cdnm help` for help."

    channel = game.channel_id
    file = Board.gen_board_image(board_content, game.id)
    SlackClient.upload_file(file.path, message, channel, token)

    if not is_nil(status.winner) do
      SlackClient.upload_file(
        Board.gen_board_image(Board.build_key(Game.get_squares(game)), game.id).path,
        "Here is the key for the game.",
        game.channel_id,
        token
      )
    else
      SlackClient.send_square_select_blocks(game.channel_id, status, token)
    end
  end

  defp status_content(game, winner) do
    if not is_nil(winner) do
      "*#{winner} wins!*"
    else
      "#{game.next} is up!"
    end
  end

  def do_execute_pass(channel_id, user_id, token) do
    game = get_game(channel_id)
    current_team = game.next

    if game do
      game = Ecto.Changeset.change(game, next: Game.get_opposite_team(game.next))
      game = Repo.update!(game)
      get_and_send_status(token, game, "#{current_team} passes.")
    else
      send_error_message(token, channel_id, user_id)
    end
  end

  defp do_execute_guess(game, guess, user_id, token) do
    if not is_nil(game) and is_nil(game.winner) do
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

        message =
          if square.type != game.next do
            game_update = Ecto.Changeset.change(game, next: Game.get_opposite_team(game.next))
            Repo.update!(game_update)
            "Incorrect! "
          else
            "Correct! "
          end

        send_status(token, status, Repo.get(Game, game.id), message)
      else
        send_error_message(game.channel_id, user_id, "Not a valid guess.")
      end
    else
      send_error_message(game.channel_id, user_id, "Not your turn.")
    end
  end

  def send_error_message(token, channel_id, user_id, err \\ nil)

  def send_error_message(token, channel_id, user_id, nil),
    do: do_send_error_message(token, channel_id, "Something went wrong.", user_id)

  def send_error_message(token, channel_id, user_id, err) when is_binary(err),
    do: do_send_error_message(token, channel_id, err, user_id)

  def send_error_message(
        token,
        channel_id,
        user_id,
        {:ok, %HTTPoison.Response{body: %{"error" => err, "ok" => false}}}
      ),
      do: do_send_error_message(token, channel_id, err, user_id)

  def send_error_message(token, channel_id, user_id, {:error, err}),
    do: do_send_error_message(token, channel_id, err, user_id)

  def do_send_error_message(token, channel_id, content, user_id) do
    SlackClient.post_ephemeral_message(channel_id, content, user_id, token)
  end

  defp get_game(channel_id) do
    Repo.one(from(Game, where: [channel: "slack", channel_id: ^channel_id]))
  end

  defp get_game_channel_name(game),
    do: "cdnm-#{Timex.format!(game.inserted_at, "%y%m%d%H%M%S", :strftime)}"

  defp get_team_token(team_id) do
    case Repo.one(from(t in Slack.Team, where: t.team_id == ^team_id)) do
      nil ->
        {:error, "Not authenticated"}

      team ->
        Phoenix.Token.decrypt(CodenamesWeb.Endpoint, @salt, team.token)
    end
  end
end
