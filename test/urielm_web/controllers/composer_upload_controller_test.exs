defmodule UrielmWeb.ComposerUploadControllerTest do
  use UrielmWeb.ConnCase, async: false

  alias Urielm.File
  alias Urielm.Fixtures
  alias Urielm.Repo

  describe "POST /forum/t/:thread_id/uploads" do
    setup do
      user = Fixtures.user_fixture()
      category = Fixtures.category_fixture()
      board = Fixtures.board_fixture(%{category_id: category.id})
      thread = Fixtures.thread_fixture(%{board_id: board.id, author_id: user.id})

      %{user: user, thread: thread}
    end

    test "stores a composer upload without external network IO", %{
      conn: conn,
      user: user,
      thread: thread
    } do
      upload = upload_fixture("diagram.png", "image/png", "fake image bytes")

      conn =
        conn
        |> log_in_user(user)
        |> post("/forum/t/#{thread.id}/uploads", %{"file" => upload})

      assert %{
               "filename" => "diagram.png",
               "content_type" => "image/png",
               "url" => "/files/" <> file_id
             } = json_response(conn, 201)

      assert %File{} = file = Repo.get(File, file_id)
      assert file.entity_type == "thread"
      assert file.entity_id == thread.id
      assert file.user_id == user.id
    end

    test "requires an authenticated user", %{conn: conn, thread: thread} do
      upload = upload_fixture("diagram.png", "image/png", "fake image bytes")

      conn = post(conn, "/forum/t/#{thread.id}/uploads", %{"file" => upload})

      assert redirected_to(conn) == "/"
      refute Repo.get_by(File, original_filename: "diagram.png")
    end

    test "returns upload validation errors as JSON", %{conn: conn, user: user, thread: thread} do
      upload = upload_fixture("payload.exe", "application/x-executable", "bad")

      conn =
        conn
        |> log_in_user(user)
        |> post("/forum/t/#{thread.id}/uploads", %{"file" => upload})

      assert %{"error" => error} = json_response(conn, 422)
      assert error =~ "not allowed"
    end

    test "rejects unverified users", %{conn: conn, user: user, thread: thread} do
      user =
        user
        |> Ecto.Changeset.change(%{email_verified: false})
        |> Repo.update!()

      upload = upload_fixture("diagram.png", "image/png", "fake image bytes")

      conn =
        conn
        |> log_in_user(user)
        |> post("/forum/t/#{thread.id}/uploads", %{"file" => upload})

      assert %{"error" => "Verify your email before uploading files"} = json_response(conn, 403)
      refute Repo.get_by(File, original_filename: "diagram.png")
    end

    test "rejects silenced users", %{conn: conn, user: user, thread: thread} do
      user =
        user
        |> Ecto.Changeset.change(%{silenced_at: DateTime.utc_now() |> DateTime.truncate(:second)})
        |> Repo.update!()

      upload = upload_fixture("diagram.png", "image/png", "fake image bytes")

      conn =
        conn
        |> log_in_user(user)
        |> post("/forum/t/#{thread.id}/uploads", %{"file" => upload})

      assert %{"error" => "Your account is silenced and cannot upload files"} =
               json_response(conn, 403)

      refute Repo.get_by(File, original_filename: "diagram.png")
    end
  end

  defp upload_fixture(filename, content_type, contents) do
    path = Path.join(System.tmp_dir!(), "#{System.unique_integer([:positive])}-#{filename}")
    Elixir.File.write!(path, contents)

    %Plug.Upload{path: path, filename: filename, content_type: content_type}
  end
end
