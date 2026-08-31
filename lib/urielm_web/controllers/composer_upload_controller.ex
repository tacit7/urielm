defmodule UrielmWeb.ComposerUploadController do
  use UrielmWeb, :controller

  alias Urielm.Files
  alias Urielm.Forum
  alias Urielm.Forum.Thread

  def create(conn, %{"thread_id" => thread_id, "file" => %Plug.Upload{} = upload}) do
    user = conn.assigns.current_user

    with %Thread{} = thread <- Forum.get_thread(thread_id),
         :ok <- Forum.authorize_comment(thread, user),
         {:ok, file} <- Files.create_file(upload, user.id, "thread", thread.id) do
      conn
      |> put_status(:created)
      |> json(%{
        filename: file.original_filename,
        content_type: file.content_type,
        url: Files.public_url(file)
      })
    else
      {:error, :thread_locked} ->
        conn
        |> put_status(:locked)
        |> json(%{error: "This thread is locked"})

      {:error, :email_unverified} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Verify your email before uploading files"})

      {:error, :silenced} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Your account is silenced and cannot upload files"})

      {:error, :board_hidden} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Thread not found"})

      {:error, :thread_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Thread not found"})

      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Thread not found"})

      {:error, reason} when is_binary(reason) ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})

      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Could not store this upload"})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Choose a file to upload"})
  end
end
