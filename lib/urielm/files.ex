defmodule Urielm.Files do
  @moduledoc """
  Context for managing file uploads and attachments.
  Generic polymorphic file attachments for any entity.
  """

  import Ecto.Query
  alias Urielm.Repo
  alias Urielm.File
  alias Urielm.Upload

  @doc """
  Create file attachment for any entity.

  ## Parameters
  - `upload` - Plug.Upload struct from form submission
  - `user_id` - ID of the user uploading the file
  - `entity_type` - Type of entity ("thread", "comment", "post", "lecture", "course")
  - `entity_id` - ID of the entity (UUID)
  - `attrs` - Optional attributes (visibility, etc.)

  ## Returns
  - `{:ok, %File{}}` - Successfully uploaded and recorded
  - `{:error, reason}` - Upload or database error
  """
  def create_file(upload, user_id, entity_type, entity_id, attrs \\ %{}) do
    with {:ok, upload_result} <- Upload.upload_file(upload, user_id) do
      %File{}
      |> File.changeset(
        Map.merge(attrs, %{
          entity_type: entity_type,
          entity_id: entity_id,
          user_id: user_id,
          storage_key: upload_result.key,
          original_filename: upload_result.filename,
          content_type: upload_result.content_type,
          byte_size: upload_result.size
        })
      )
      |> Repo.insert()
    end
  end

  @doc """
  List all files for an entity (excludes soft-deleted).
  """
  def list_entity_files(entity_type, entity_id) do
    File
    |> where([f], f.entity_type == ^entity_type and f.entity_id == ^entity_id)
    |> where([f], is_nil(f.deleted_at))
    |> order_by([f], asc: f.inserted_at)
    |> Repo.all()
  end

  @doc """
  Get a single file by ID.
  """
  def get_file!(id), do: Repo.get!(File, id)

  @doc """
  Get files uploaded by a user.
  """
  def list_user_files(user_id) do
    File
    |> where([f], f.user_id == ^user_id)
    |> where([f], is_nil(f.deleted_at))
    |> order_by([f], desc: f.inserted_at)
    |> Repo.all()
  end

  @doc """
  Soft delete a file.
  """
  def soft_delete_file(%File{} = file) do
    file
    |> File.soft_delete_changeset()
    |> Repo.update()
  end

  @doc """
  Hard delete a file (removes from R2 and DB).
  """
  def delete_file(%File{} = file) do
    with :ok <- Upload.delete_file(file.storage_key),
         {:ok, _} <- Repo.delete(file) do
      {:ok, file}
    end
  end

  @doc """
  Check if user can access file based on visibility.
  """
  def can_access_file?(%{id: user_id}, %File{user_id: file_user_id, visibility: "private"}) do
    user_id == file_user_id
  end

  def can_access_file?(_, %File{visibility: "public"}), do: true

  # TODO: Implement participants check - requires entity-specific membership logic
  def can_access_file?(_, %File{visibility: "participants"}), do: true

  @doc """
  Check if a file is an image.
  """
  def image?(%File{content_type: content_type}), do: Upload.image?(content_type)

  @doc """
  Check if a file is a document.
  """
  def document?(%File{content_type: content_type}), do: Upload.document?(content_type)
end
