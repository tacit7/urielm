defmodule Urielm.Forum.CategoryWatch do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @watch_levels ~w(watching tracking normal muted)

  schema "category_watches" do
    belongs_to(:user, Urielm.Accounts.User, type: :id)
    belongs_to(:category, Urielm.Forum.Category)
    field(:watch_level, :string, default: "normal")

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(watch, attrs) do
    watch
    |> cast(attrs, [:user_id, :category_id, :watch_level])
    |> validate_required([:user_id, :category_id, :watch_level])
    |> validate_inclusion(:watch_level, @watch_levels)
    |> unique_constraint([:user_id, :category_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:category_id)
  end
end
