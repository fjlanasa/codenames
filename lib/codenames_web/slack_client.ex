defmodule CodenamesWeb.SlackClient do
  use HTTPoison.Base

  @base_url "https://slack.com/api"
  @post_message_path "/chat.postMessage"
  @post_ephemeral_message_path "/chat.postEphemeral"
  @create_conversations_path "/conversations.create"
  @open_conversations_path "/conversations.open"
  @join_conversation_path "/conversations.join"
  @oauth_path "/oauth.v2.access"
  @file_upload_path "/files.upload"
  @token System.get_env("SLACK_KEY")
  @client_id System.get_env("SLACK_CLIENT_ID")
  @client_secret System.get_env("SLACK_CLIENT_SECRET")

  def build_header(token, content_type \\ "application/json") do
    [Authorization: "Bearer #{token || @token}", "Content-Type": content_type]
  end

  def build_url(path) do
    @base_url <> path
  end

  def join_conversation(channel, token) do
    post(
      build_url(@join_conversation_path),
      Jason.encode!(%{channel: channel}),
      build_header(token)
    )
  end

  def post_message(channel, text, token) do
    post(
      build_url(@post_message_path),
      Jason.encode!(%{channel: channel, text: text, reply_broadcast: true}),
      build_header(token)
    )
  end

  def post_ephemeral_message(channel, text, user_id, token) do
    post(
      build_url(@post_ephemeral_message_path),
      Jason.encode!(%{channel: channel, text: text, user: user_id}),
      build_header(token)
    )
  end

  def create_conversation(name, token) do
    post(
      build_url(@create_conversations_path),
      Jason.encode!(%{name: name}),
      build_header(token)
    )
  end

  def open_conversation(user_ids, token) do
    post(
      build_url(@open_conversations_path),
      Jason.encode!(%{users: Enum.join(user_ids, ",")}),
      build_header(token)
    )
  end

  def upload_file(file_path, message, channel, token) do
    post(
      build_url(@file_upload_path),
      {:multipart,
       [
         {"", channel, {"form-data", [{"name", :channels}]}, []},
         {"", message, {"form-data", [{"name", :initial_comment}]}, []},
         {"", file_path, {"form-data", [{"name", :file}]}, []},
         {:file, file_path, []}
       ]},
      build_header(token, "multipart/form-data")
    )
  end

  def send_help(response_url, token) do
    post(
      response_url,
      Jason.encode!(%{
        "response_type" => "in_channel",
        "text" =>
          "*Commands*\n\n*/cdnm new* _@blue_clue_giver_ _@red_clue_giver_ _first_team_\n```Starts a new game.\n\nOptions:\n* @blue_clue_giver: handle of clue giver for blue team\n* @red_clue_giver: handle of clue giver for red team\n* first_team: BLUE or RED (optional, default BLUE)\n\nExample:\n/cdnm new @Joe @Jane RED```\n*/cdnm guess* _space_\n```Makes a guess.\n\nOptions:\n* space: column and row of space\n\nExample:\n/cdnm guess a3```\n*cdnm pass*```Ends the guessing team's turn```\n*/cdnm status*```Returns the game's current status```\n*/cdnm quit* ```Ends the current game```\n"
      }),
      build_header(token)
    )
  end

  def send_square_select_blocks(channel_id, status, token) do
    blocks = [
      %{
        type: "actions",
        block_id: "actions1",
        elements: [
          %{
            type: "static_select",
            placeholder: %{
              type: "plain_text",
              text: "Which witch is the witchiest witch?"
            },
            action_id: "select_2",
            options:
              Enum.map(status.available, fn x ->
                %{text: %{type: "plain_text", text: x.word}, value: "#{x.column}#{x.row}"}
              end)
          },
          %{
            type: "button",
            text: %{
              type: "plain_text",
              text: "Pass"
            },
            value: "pass",
            action_id: "button_1"
          }
        ]
      }
    ]

    post(
      build_url(@post_message_path),
      Jason.encode!(%{channel: channel_id, text: "", blocks: blocks}),
      build_header(token)
    )
  end

  def get_oauth_access(code) do
    post(
      build_url(@oauth_path),
      {:form, [{:code, code}, {:client_id, @client_id}, {:client_secret, @client_secret}]},
      build_header(@token, "application/x-www-form-urlencoded")
    )
  end

  def process_response_body("ok"), do: %{"ok" => true}

  def process_response_body(body) do
    Jason.decode!(body)
  end
end
