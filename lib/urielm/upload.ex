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
  # sobelow_skip ["Traversal.FileModule"]
  def upload_file(%Plug.Upload{} = file, user_id) do
    with :ok <- validate_file(file),
         {:ok, key} <- generate_key(file.filename, user_id),
         {:ok, file_binary} <- File.read(file.path),
         :ok <- upload_to_r2(key, file_binary, file.content_type) do
      {:ok,
       %{
         url: public_url(key),
         filename: file.filename,
         content_type: file.content_type,
         size: File.stat!(file.path).size,
         key: key
       }}
    end
  end

  @doc """
  Download a stored file from the configured storage backend.
  """
  def download_file(key) when is_binary(key) do
    case storage_adapter() do
      :r2 -> download_from_r2(key)
      :noop -> {:error, :not_found}
    end
  end

  @doc """
  Delete a file from R2 storage.
  """
  def delete_file(key) do
    case storage_adapter() do
      :r2 -> delete_from_r2(key)
      :noop -> :ok
    end
  end

  # Private functions

  defp validate_file(%Plug.Upload{} = file) do
    with :ok <- validate_extension(file.filename),
         :ok <- validate_mime_type(file.content_type),
         :ok <- validate_extension_matches_mime_type(file.filename, file.content_type),
         :ok <- validate_size(File.stat!(file.path).size),
         :ok <- validate_file_signature(file.path, file.content_type) do
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

  defp validate_extension_matches_mime_type(filename, content_type) do
    ext = Path.extname(filename) |> String.downcase()

    allowed =
      case ext do
        ext when ext in [".jpg", ".jpeg"] -> ["image/jpeg"]
        ".png" -> ["image/png"]
        ".gif" -> ["image/gif"]
        ".webp" -> ["image/webp"]
        ".pdf" -> ["application/pdf"]
        ".doc" -> ["application/msword"]
        ".docx" -> ["application/vnd.openxmlformats-officedocument.wordprocessingml.document"]
        ".txt" -> ["text/plain"]
        _ -> []
      end

    if content_type in allowed do
      :ok
    else
      {:error, "File extension does not match content type"}
    end
  end

  # sobelow_skip ["Traversal.FileModule"]
  defp validate_file_signature(path, content_type) do
    with {:ok, bytes} <- File.read(path),
         true <- content_matches_type?(bytes, content_type) do
      :ok
    else
      _ -> {:error, "File contents do not match content type"}
    end
  end

  defp content_matches_type?(<<0xFF, 0xD8, 0xFF, _rest::binary>>, "image/jpeg"), do: true

  defp content_matches_type?(<<0x89, "PNG\r\n", 0x1A, "\n", _rest::binary>>, "image/png"),
    do: true

  defp content_matches_type?(<<"GIF87a", _rest::binary>>, "image/gif"), do: true
  defp content_matches_type?(<<"GIF89a", _rest::binary>>, "image/gif"), do: true

  defp content_matches_type?(<<"RIFF", _size::little-32, "WEBP", _rest::binary>>, "image/webp"),
    do: true

  defp content_matches_type?(<<"%PDF-", _rest::binary>>, "application/pdf"), do: true

  defp content_matches_type?(
         <<0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1, _rest::binary>>,
         "application/msword"
       ),
       do: true

  defp content_matches_type?(
         <<"PK", 0x03, 0x04, _rest::binary>>,
         "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
       ),
       do: true

  defp content_matches_type?(bytes, "text/plain"), do: String.valid?(bytes)
  defp content_matches_type?(_bytes, _content_type), do: false

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
    case storage_adapter() do
      :r2 -> do_upload_to_r2(key, file_binary, content_type)
      :noop -> :ok
    end
  end

  defp do_upload_to_r2(key, file_binary, content_type) do
    bucket = Application.get_env(:urielm, :uploads)[:bucket]

    S3.put_object(bucket, key, file_binary, content_type: content_type)
    |> ExAws.request()
    |> case do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, "Upload failed: #{inspect(reason)}"}
    end
  end

  defp download_from_r2(key) do
    bucket = Application.get_env(:urielm, :uploads)[:bucket]

    S3.get_object(bucket, key)
    |> ExAws.request()
    |> case do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, _reason} -> {:error, :not_found}
    end
  end

  @doc "Returns the configured public URL for a stored upload key."
  def public_url(key) when is_binary(key) do
    public_url = Application.get_env(:urielm, :uploads)[:public_url]
    "#{public_url}/#{key}"
  end

  defp delete_from_r2(key) do
    bucket = Application.get_env(:urielm, :uploads)[:bucket]

    S3.delete_object(bucket, key)
    |> ExAws.request()
    |> case do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp storage_adapter do
    Application.get_env(:urielm, :uploads, [])
    |> Keyword.get(:storage_adapter, :r2)
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
