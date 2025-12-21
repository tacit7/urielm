defmodule Urielm.Content.VideoCompletion do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "video_completions" do
    belongs_to :user, Urielm.Accounts.User, type: :id
    belongs_to :video, Urielm.Content.Video, type: :binary_id

    field :completed_at, :utc_datetime
  end

  @doc false
  def changeset(completion, attrs) do
    completion
    |> cast(attrs, [:user_id, :video_id, :completed_at])
    |> validate_required([:user_id, :video_id, :completed_at])
    |> unique_constraint([:user_id, :video_id], name: :video_completions_user_id_video_id_key)
  end
end
