defmodule Urielm.Engagement.Discussion do
  @moduledoc """
  Maps any content item to its forum thread for comments.

  This enables a unified comment system across all content types
  (videos, lessons, prompts, posts) by linking them to forum threads.

  Lazy creation: thread is created when first comment is posted
  or when comments UI is opened.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @valid_targets ~w(video lesson prompt post course)

  schema "discussions" do
    field(:target_type, :string)
    field(:target_id, :integer)

    belongs_to(:thread, Urielm.Forum.Thread, type: :binary_id)

    timestamps()
  end

  @doc false
  def changeset(discussion, attrs) do
    discussion
    |> cast(attrs, [:target_type, :target_id, :thread_id])
    |> validate_required([:target_type, :target_id, :thread_id])
    |> validate_inclusion(:target_type, @valid_targets)
    |> foreign_key_constraint(:thread_id)
    |> unique_constraint([:target_type, :target_id],
      name: :discussions_target_type_target_id_index
    )
    |> unique_constraint([:thread_id],
      name: :discussions_thread_id_index
    )
  end

  def valid_targets, do: @valid_targets
end
