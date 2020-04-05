defmodule CodenamesWeb.SlackClient do
  use HTTPoison.Base

  @base_url "https://slack.com/api"
  @post_message_path "/chat.postMessage"
  @create_conversations_path "/conversations.create"
  @open_conversations_path "/conversations.open"
  @join_conversation_path "/conversations.join"
  @file_upload_path "/files.upload"
  @token Application.get_env(:codenames, :slack_key)

  defp build_header(content_type \\ "application/json") do
    [Authorization: "Bearer #{@token}", "Content-Type": content_type]
  end

  def build_url(path) do
    @base_url <> path
  end

  def join_conversation(channel) do
    HTTPoison.post(
      build_url(@join_conversation_path),
      Jason.encode!(%{channel: channel}),
      build_header()
    )
  end

  def post_message(channel, text) do
    HTTPoison.post(
      build_url(@post_message_path),
      Jason.encode!(%{channel: channel, text: text, reply_broadcast: true}),
      build_header()
    )
  end

  def create_conversation(name) do
    HTTPoison.post(
      build_url(@create_conversations_path),
      Jason.encode!(%{name: name}),
      build_header()
    )
  end

  def open_conversation(user_ids) do
    HTTPoison.post(
      build_url(@open_conversations_path),
      Jason.encode!(%{users: Enum.join(user_ids, ",")}),
      build_header()
    )
  end

  def upload_file(file_path, message, channel) do
    HTTPoison.post(
      build_url(@file_upload_path),
      {:multipart,
       [
         {"", channel, {"form-data", [{"name", :channels}]}, []},
         {"", "name.jpg", {"form-data", [{"name", :filename}]}, []},
         {"", message, {"form-data", [{"name", :initial_comment}]}, []},
         {"", file_path, {"form-data", [{"name", :file}]}, []},
         {:file, file_path, []}
       ]},
      build_header("multipart/form-data")
    )
  end
end
