defmodule Urielm.Upload do
  @moduledoc """
  Handles file uploads to Cloudflare R2 (S3-compatible storage).
  """

  alias ExAws.S3

  @allowed_image_types ~w(.jpg .jpeg .png .gif .webp)
  @allowed_document_types ~w(.pdf .doc .docx .txt)
  @allowed_extensions @allowed_image_types ++ @allowed_document_types

  @allowed_mime_types [
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/webp",
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "text/plain"
  ]

  @doc """
  Upload a file to R2 storage.

  ## Parameters
  - `file` - The uploaded file (Plug.Upload struct)
  - `user_id` - The ID of the user uploading the file

  ## Returns
  - `{:ok, %{url: url, filename: filename, content_type: content_type, size: size}}`
  - `{:error, reason}`
  """
  def upload_file(%Plug.Upload{} = file, user_id) do
    with :ok <- validate_file(file),
         {:ok, key} <- generate_key(file.filename, user_id),
         {:ok, file_binary} <- File.read(file.path),
         :ok <- upload_to_r2(key, file_binary, file.content_type) do
      {:ok,
       %{
         url: build_public_url(key),
         filename: file.filename,
         content_type: file.content_type,
         size: file.size,
         key: key
       }}
    end
  end

  @doc """
  Delete a file from R2 storage.
  """
  def delete_file(key) do
    bucket = Application.get_env(:urielm, :uploads)[:bucket]

    S3.delete_object(bucket, key)
    |> ExAws.request()
    |> case do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  # Private functions

  defp validate_file(%Plug.Upload{} = file) do
    with :ok <- validate_extension(file.filename),
         :ok <- validate_mime_type(file.content_type),
         :ok <- validate_size(file.size) do
      :ok
    end
  end

  defp validate_extension(filename) do
    ext = Path.extname(filename) |> String.downcase()

    if ext in @allowed_extensions do
      :ok
    else
      {:error, "File type not allowed. Allowed types: #{Enum.join(@allowed_extensions, ", ")}"}
    end
  end

  defp validate_mime_type(content_type) do
    if content_type in @allowed_mime_types do
      :ok
    else
      {:error, "Content type not allowed"}
    end
  end

  defp validate_size(size) do
    max_size = Application.get_env(:urielm, :uploads)[:max_file_size]

    if size <= max_size do
      :ok
    else
      max_mb = div(max_size, 1_024 * 1_024)
      {:error, "File too large. Maximum size is #{max_mb}MB"}
    end
  end

  defp generate_key(filename, user_id) do
    # Generate unique key: uploads/{user_id}/{timestamp}-{uuid}-{filename}
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    uuid = Ecto.UUID.generate() |> String.slice(0..7)
    safe_filename = sanitize_filename(filename)
    key = "uploads/#{user_id}/#{timestamp}-#{uuid}-#{safe_filename}"

    {:ok, key}
  end

  defp sanitize_filename(filename) do
    filename
    |> String.replace(~r/[^a-zA-Z0-9._-]/, "_")
    |> String.slice(0..100)
  end

  defp upload_to_r2(key, file_binary, content_type) do
    bucket = Application.get_env(:urielm, :uploads)[:bucket]

    S3.put_object(bucket, key, file_binary,
      content_type: content_type,
      acl: :public_read
    )
    |> ExAws.request()
    |> case do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, "Upload failed: #{inspect(reason)}"}
    end
  end

  defp build_public_url(key) do
    public_url = Application.get_env(:urielm, :uploads)[:public_url]
    "#{public_url}/#{key}"
  end

  @doc """
  Check if a file type is an image.
  """
  def image?(content_type) do
    content_type in ["image/jpeg", "image/png", "image/gif", "image/webp"]
  end

  @doc """
  Check if a file type is a document.
  """
  def document?(content_type) do
    content_type in [
      "application/pdf",
      "application/msword",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "text/plain"
    ]
  end
end
