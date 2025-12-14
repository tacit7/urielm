defmodule Urielm.Content.Post do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "posts" do
    field(:title, :string)
    field(:slug, :string)
    field(:body, :string)
    field(:excerpt, :string)
    field(:status, :string, default: "draft")
    field(:published_at, :utc_datetime)
    field(:hero_image, :string)

    belongs_to(:author, Urielm.Accounts.User)

    timestamps(type: :utc_datetime)
  end

  @statuses ~w(draft published)

  def changeset(post, attrs) do
    post
    |> cast(attrs, [
      :title,
      :slug,
      :body,
      :excerpt,
      :status,
      :published_at,
      :author_id,
      :hero_image
    ])
    |> validate_required([:title, :slug, :body, :status])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:slug)
  end

  def published(query \\ __MODULE__) do
    from(p in query,
      where:
        p.status == "published" and not is_nil(p.published_at) and
          p.published_at <= ^DateTime.utc_now()
    )
  end
end
