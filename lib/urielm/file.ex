defmodule Urielm.File do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "files" do
    # Polymorphic association
    field(:entity_type, :string)
    field(:entity_id, :binary_id)

    # Storage metadata (required)
    field(:storage_key, :string)
    field(:original_filename, :string)
    field(:content_type, :string)
    field(:byte_size, :integer)

    # Optional metadata
    field(:visibility, :string, default: "public")
    field(:checksum_sha256, :binary)
    field(:width, :integer)
    field(:height, :integer)
    field(:deleted_at, :utc_datetime)

    belongs_to(:user, Urielm.Accounts.User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [
      :entity_type,
      :entity_id,
      :storage_key,
      :original_filename,
      :content_type,
      :byte_size,
      :visibility,
      :checksum_sha256,
      :width,
      :height,
      :user_id
    ])
    |> maybe_generate_id()
    |> validate_required([
      :entity_type,
      :entity_id,
      :storage_key,
      :original_filename,
      :content_type,
      :byte_size,
      :user_id
    ])
    |> validate_inclusion(:entity_type, ~w(thread comment post lecture course))
    |> validate_inclusion(:visibility, ~w(public private participants))
    |> validate_number(:byte_size, greater_than: 0)
    |> unique_constraint(:storage_key)
    |> foreign_key_constraint(:user_id)
  end

  defp maybe_generate_id(changeset) do
    case get_field(changeset, :id) do
      nil -> put_change(changeset, :id, Uniq.UUID.uuid7())
      _ -> changeset
    end
  end

  def soft_delete_changeset(file) do
    change(file, deleted_at: DateTime.utc_now())
  end
end
