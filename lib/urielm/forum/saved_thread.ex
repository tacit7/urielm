defmodule Urielm.Forum.SavedThread do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "saved_threads" do
    belongs_to(:user, Urielm.Accounts.User, type: :id)
    belongs_to(:thread, Urielm.Forum.Thread)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(saved_thread, attrs) do
    saved_thread
    |> cast(attrs, [:user_id, :thread_id])
    |> validate_required([:user_id, :thread_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:thread_id)
    |> unique_constraint([:user_id, :thread_id])
  end
end
