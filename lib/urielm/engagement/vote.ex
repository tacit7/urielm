defmodule Urielm.Engagement.Vote do
  @moduledoc """
  Unified voting schema for thumbs up/down across all content types.

  Target types: thread, comment, video, lesson, prompt, post
  Values: -1 (downvote) or +1 (upvote)

  Toggle logic:
  - none + up => +1
  - +1 + up => remove
  - -1 + up => switch to +1
  - (mirror for down)
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @valid_targets ~w(thread comment video lesson prompt post)
  @valid_values [-1, 1]

  schema "votes" do
    field(:target_type, :string)
    field(:target_id, :binary_id)
    field(:value, :integer)

    belongs_to(:user, Urielm.Accounts.User, type: :id)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:user_id, :target_type, :target_id, :value])
    |> validate_required([:user_id, :target_type, :target_id, :value])
    |> validate_inclusion(:target_type, @valid_targets)
    |> validate_inclusion(:value, @valid_values)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :target_type, :target_id],
      name: :votes_user_id_target_type_target_id_index
    )
  end

  def valid_targets, do: @valid_targets
  def valid_values, do: @valid_values
end
