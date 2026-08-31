defmodule UrielmWeb.FileController do
  use UrielmWeb, :controller

  alias Urielm.Files

  @allowed_response_content_types ~w(
    image/jpeg
    image/png
    image/gif
    image/webp
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    text/plain
  )

  # sobelow_skip ["XSS.SendResp", "XSS.ContentType"]
  def show(conn, %{"id" => id}) do
    user = conn.assigns[:current_user]

    with file when not is_nil(file) <- Files.get_file(id),
         true <- Files.can_access_file?(user, file),
         {:ok, content_type} <- response_content_type(file.content_type),
         {:ok, body} <- Files.download_file(file) do
      conn
      |> put_resp_content_type(content_type)
      |> put_resp_header("x-content-type-options", "nosniff")
      |> put_resp_header("content-disposition", content_disposition(file.original_filename))
      |> send_resp(:ok, body)
    else
      nil -> send_resp(conn, :not_found, "Not found")
      false -> send_resp(conn, :not_found, "Not found")
      {:error, :not_found} -> send_resp(conn, :not_found, "Not found")
      {:error, :invalid_content_type} -> send_resp(conn, :not_found, "Not found")
    end
  end

  defp response_content_type(content_type) when content_type in @allowed_response_content_types do
    {:ok, content_type}
  end

  defp response_content_type(_content_type), do: {:error, :invalid_content_type}

  defp content_disposition(filename) do
    safe_filename = String.replace(filename || "download", ~r/["\r\n]/, "_")
    ~s(inline; filename="#{safe_filename}")
  end
end
