defmodule CodenamesWeb.S3Client do
  alias ExAws.S3
  @bucket "cdnm-boards"

  def put_board(content, channel_id) do
    unix = DateTime.utc_now() |> DateTime.to_unix()
    path = "#{channel_id}/#{unix}.jpg"

    case S3.put_object(@bucket, path, content) |> ExAws.request() do
      {:ok, _} ->
        {:ok, "https://#{@bucket}.s3.amazonaws.com/#{path}"}

      err ->
        err
    end
  end
end
