defmodule Urielm.Files do
  @moduledoc """
  Context for managing file uploads and attachments.
  Generic polymorphic file attachments for any entity.
  """

  import Ecto.Query
  alias Urielm.Repo
  alias Urielm.File
  alias Urielm.Forum
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

  def get_file(id) when is_binary(id) do
    File
    |> where([f], f.id == ^id)
    |> where([f], is_nil(f.deleted_at))
    |> Repo.one()
  end

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

  def can_access_file?(user, %File{} = file) do
    forum_parent_visible?(user, file) and file_visibility_allows?(user, file)
  end

  defp forum_parent_visible?(user, %File{entity_type: "thread", entity_id: thread_id}) do
    not is_nil(Forum.get_thread(thread_id, viewer: user, allow_removed?: available_admin?(user)))
  end

  defp forum_parent_visible?(user, %File{entity_type: "comment", entity_id: comment_id}) do
    case Repo.get(Urielm.Forum.Comment, comment_id) do
      nil ->
        false

      comment ->
        (not comment.is_removed or available_admin?(user)) and
          forum_parent_visible?(user, %File{entity_type: "thread", entity_id: comment.thread_id})
    end
  end

  defp forum_parent_visible?(_user, %File{}), do: true

  defp file_visibility_allows?(%{id: user_id}, %File{user_id: file_user_id, visibility: "private"}) do
    user_id == file_user_id
  end

  defp file_visibility_allows?(_, %File{visibility: "public"}), do: true

  defp file_visibility_allows?(user, %File{visibility: "participants"} = file) do
    participant_can_access_file?(user, file)
  end

  defp file_visibility_allows?(_, %File{}), do: false

  defp participant_can_access_file?(%{id: user_id}, %File{user_id: user_id}), do: true

  defp participant_can_access_file?(%{id: user_id} = user, %File{} = file) do
    available_admin?(%{id: user_id}) or visible_thread_attachment?(user, file)
  end

  defp participant_can_access_file?(user, file), do: visible_thread_attachment?(user, file)

  defp available_admin?(%{id: user_id}) do
    case Repo.get(Urielm.Accounts.User, user_id) do
      %Urielm.Accounts.User{is_admin: true, active: true} = persisted_user ->
        not Urielm.Accounts.User.suspended?(persisted_user)

      _ ->
        false
    end
  end

  defp available_admin?(_user), do: false

  defp visible_thread_attachment?(_user, %File{entity_type: "thread", entity_id: thread_id}) do
    case Forum.get_thread(thread_id) do
      nil -> false
      %{board: %{is_hidden: true}} -> false
      _thread -> true
    end
  end

  defp visible_thread_attachment?(_user, %File{}), do: false

  @doc """
  Check if a file is an image.
  """
  def image?(%File{content_type: content_type}), do: Upload.image?(content_type)

  @doc """
  Check if a file is a document.
  """
  def document?(%File{content_type: content_type}), do: Upload.document?(content_type)

  @doc "Returns the public URL for a stored file attachment."
  def public_url(%File{id: id}), do: "/files/#{id}"

  def download_file(%File{storage_key: storage_key}), do: Upload.download_file(storage_key)
end
