defmodule Reddit.Content.Topic do
  use Ecto.Schema
  import Ecto.Changeset

  schema "topics" do
    field :name, :string
    field :slug, :string
    field :description, :string
    has_many :links, Reddit.Content.Link, foreign_key: :topic_id
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:name, :slug, :description])
    |> validate_required([:name, :slug])
    |> unique_constraint(:name)
    |> unique_constraint(:slug)
    |> maybe_generate_slug()
  end

  # Generate slug from name if not provided
  defp maybe_generate_slug(%Ecto.Changeset{valid?: true, changes: %{name: name}} = changeset)
       when not is_nil(name) do
    case get_field(changeset, :slug) do
      nil -> put_change(changeset, :slug, slugify(name))
      _slug -> changeset
    end
  end

  defp maybe_generate_slug(changeset), do: changeset

  # Simple slug generation function (converts to lowercase and replaces spaces with dashes)
  defp slugify(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
  end
end
