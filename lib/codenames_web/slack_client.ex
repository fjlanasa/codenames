defmodule CodenamesWeb.SlackClient do
  use HTTPoison.Base

  @base_url "https://slack.com/api"
  @post_message_path "/chat.postMessage"
  @post_ephemeral_message_path "/chat.postEphemeral"
  @create_conversations_path "/conversations.create"
  @open_conversations_path "/conversations.open"
  @join_conversation_path "/conversations.join"
  @file_upload_path "/files.upload"
  @token System.get_env("SLACK_KEY")

  defp build_header(content_type \\ "application/json") do
    [Authorization: "Bearer #{@token}", "Content-Type": content_type]
  end

  def build_url(path) do
    @base_url <> path
  end

  def join_conversation(channel) do
    post(
      build_url(@join_conversation_path),
      Jason.encode!(%{channel: channel}),
      build_header()
    )
  end

  def post_message(channel, text) do
    post(
      build_url(@post_message_path),
      Jason.encode!(%{channel: channel, text: text, reply_broadcast: true}),
      build_header()
    )
  end

  def post_ephemeral_message(channel, text, user_id) do
    post(
      build_url(@post_ephemeral_message_path),
      Jason.encode!(%{channel: channel, text: text, user: user_id}),
      build_header()
    )
  end

  def create_conversation(name) do
    post(
      build_url(@create_conversations_path),
      Jason.encode!(%{name: name}),
      build_header()
    )
  end

  def open_conversation(user_ids) do
    post(
      build_url(@open_conversations_path),
      Jason.encode!(%{users: Enum.join(user_ids, ",")}),
      build_header()
    )
  end

  def upload_file(file_path, message, channel) do
    post(
      build_url(@file_upload_path),
      {:multipart,
       [
         {"", channel, {"form-data", [{"name", :channels}]}, []},
         {"", message, {"form-data", [{"name", :initial_comment}]}, []},
         {"", file_path, {"form-data", [{"name", :file}]}, []},
         {:file, file_path, []}
       ]},
      build_header("multipart/form-data")
    )
  end

  def send_help(channel_id) do
    post_message(
      channel_id,
      "*Commands*\n\n>*cdnm new* _@blue_clue_giver_ _@red_clue_giver_ _first_team_\n```Starts a new game.\n\nOptions:\n* @blue_clue_giver: handle of clue giver for blue team\n* @red_clue_giver: handle of clue giver for red team\n* first_team: BLUE or RED (optional, default BLUE)\n\nExample:\ncdnm new @Joe @Jane RED```\n*cdnm guess* _space_\n```Makes a guess. Must be entered by the guessing team's clue giver.\n\nOptions:\n* space: column and row of space\n\nExample:\ncdnm guess a3```\n*cdnm pass*```Ends the guessing team's turn```\n*cdnm status*```Returns the game's current status```\n*cdnm quit* ```Ends the current game```\n>"
    )
  end

  def process_response_body("ok"), do: %{"ok" => true}

  def process_response_body(body) do
    Jason.decode!(body)
  end
end
