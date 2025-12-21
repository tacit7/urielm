defmodule Urielm.FilesTest do
  use Urielm.DataCase

  alias Urielm.Files
  alias Urielm.File

  import Urielm.Fixtures

  describe "create_file/5" do
    setup do
      user = user_fixture()
      thread = thread_fixture(%{author_id: user.id})
      upload = create_upload_fixture("test.jpg", "image/jpeg", "fake image data")

      %{user: user, thread: thread, upload: upload}
    end

    test "creates file with valid upload", %{user: user, thread: thread, upload: upload} do
      assert {:ok, %File{} = file} =
               Files.create_file(upload, user.id, "thread", thread.id)

      assert file.entity_type == "thread"
      assert file.entity_id == thread.id
      assert file.user_id == user.id
      assert file.original_filename == "test.jpg"
      assert file.content_type == "image/jpeg"
      assert file.visibility == "public"
      assert is_binary(file.storage_key)
      assert String.starts_with?(file.storage_key, "uploads/#{user.id}/")
    end

    test "creates file with custom visibility", %{user: user, thread: thread, upload: upload} do
      assert {:ok, file} =
               Files.create_file(upload, user.id, "thread", thread.id, %{visibility: "private"})

      assert file.visibility == "private"
    end

    test "generates UUID v7 for file ID", %{user: user, thread: thread, upload: upload} do
      assert {:ok, file} = Files.create_file(upload, user.id, "thread", thread.id)

      # UUID v7 format check - should have timestamp prefix
      assert is_binary(file.id)
      assert byte_size(file.id) == 16
    end

    test "rejects invalid entity type", %{user: user, thread: thread, upload: upload} do
      assert {:error, changeset} =
               Files.create_file(upload, user.id, "invalid_type", thread.id)

      assert "is invalid" in errors_on(changeset).entity_type
    end

    test "rejects files over size limit", %{user: user, thread: thread} do
      large_content = String.duplicate("x", 11_000_000)
      large_upload = create_upload_fixture("large.jpg", "image/jpeg", large_content)

      assert {:error, error_msg} = Files.create_file(large_upload, user.id, "thread", thread.id)
      assert error_msg =~ "too large"
    end

    test "rejects invalid file types", %{user: user, thread: thread} do
      bad_upload = create_upload_fixture("script.exe", "application/x-executable", "malicious")

      assert {:error, error_msg} = Files.create_file(bad_upload, user.id, "thread", thread.id)
      assert error_msg =~ "not allowed"
    end
  end

  describe "list_entity_files/2" do
    setup do
      user = user_fixture()
      thread = thread_fixture(%{author_id: user.id})
      upload = create_upload_fixture("test.jpg", "image/jpeg")

      {:ok, file1} = Files.create_file(upload, user.id, "thread", thread.id)
      {:ok, file2} = Files.create_file(upload, user.id, "thread", thread.id)

      %{user: user, thread: thread, files: [file1, file2]}
    end

    test "returns all files for an entity", %{thread: thread, files: files} do
      result = Files.list_entity_files("thread", thread.id)

      assert length(result) == 2
      assert Enum.all?(result, &(&1.entity_type == "thread"))
      assert Enum.all?(result, &(&1.entity_id == thread.id))
    end

    test "excludes soft-deleted files", %{thread: thread, files: [file1, _file2]} do
      {:ok, _} = Files.soft_delete_file(file1)

      result = Files.list_entity_files("thread", thread.id)

      assert length(result) == 1
      refute Enum.any?(result, &(&1.id == file1.id))
    end

    test "returns empty list for entity with no files", %{user: user} do
      thread2 = thread_fixture(%{author_id: user.id})

      assert Files.list_entity_files("thread", thread2.id) == []
    end
  end

  describe "soft_delete_file/1" do
    setup do
      user = user_fixture()
      thread = thread_fixture(%{author_id: user.id})
      upload = create_upload_fixture("test.jpg", "image/jpeg")

      {:ok, file} = Files.create_file(upload, user.id, "thread", thread.id)

      %{file: file}
    end

    test "marks file as deleted", %{file: file} do
      assert {:ok, updated_file} = Files.soft_delete_file(file)

      assert updated_file.deleted_at != nil
      refute is_nil(Repo.get(File, file.id))
    end
  end

  describe "can_access_file?/2" do
    setup do
      owner = user_fixture()
      other_user = user_fixture()
      thread = thread_fixture(%{author_id: owner.id})

      %{owner: owner, other_user: other_user, thread: thread}
    end

    test "allows access to public files", %{owner: owner, other_user: other_user, thread: thread} do
      upload = create_upload_fixture("public.jpg", "image/jpeg")

      {:ok, file} =
        Files.create_file(upload, owner.id, "thread", thread.id, %{visibility: "public"})

      assert Files.can_access_file?(other_user, file)
      assert Files.can_access_file?(owner, file)
    end

    test "restricts private files to owner only", %{
      owner: owner,
      other_user: other_user,
      thread: thread
    } do
      upload = create_upload_fixture("private.jpg", "image/jpeg")

      {:ok, file} =
        Files.create_file(upload, owner.id, "thread", thread.id, %{visibility: "private"})

      assert Files.can_access_file?(owner, file)
      refute Files.can_access_file?(other_user, file)
    end
  end

  describe "image? and document?" do
    test "correctly identifies images" do
      file = %File{content_type: "image/jpeg"}
      assert Files.image?(file)
      refute Files.document?(file)
    end

    test "correctly identifies documents" do
      file = %File{content_type: "application/pdf"}
      assert Files.document?(file)
      refute Files.image?(file)
    end
  end

  # Test helpers

  defp create_test_file(filename, content) do
    path = Path.join(System.tmp_dir!(), filename)
    :ok = :file.write_file(path, content)
    path
  end

  defp create_upload_fixture(filename, content_type, content \\ "test content") do
    path = create_test_file(filename, content)
    {:ok, stat} = :file.read_file_info(path)
    size = elem(stat, 1)

    %{
      __struct__: Plug.Upload,
      path: path,
      filename: filename,
      content_type: content_type,
      size: size
    }
  end
end
