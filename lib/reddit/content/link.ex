defmodule Reddit.Content.Link do
  use Ecto.Schema
  import Ecto.Changeset

  schema "links" do
    field :url, :string
    field :title, :string
    field :body, :string
    field :posted_at, :utc_datetime_usec
    field :score, :integer, default: 0

    belongs_to :user, Reddit.Accounts.User, foreign_key: :user_id
    belongs_to :topic, Reddit.Content.Topic, foreign_key: :topic_id
    has_many :comments, Reddit.Content.Comment, foreign_key: :link_id

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(link, attrs) do
    link
    |> cast(attrs, [:url, :title, :body, :user_id, :topic_id, :score, :posted_at])
    |> validate_required([:url, :title, :user_id, :topic_id, :posted_at])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:topic_id)
    |> validate_url(:url)
  end

  # Basic URL validation
  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, url ->
      uri = URI.parse(url)

      case uri do
        %URI{scheme: nil} ->
          [{field, "URL must include a scheme (e.g., http://, https://)"}]
        %URI{host: nil} ->
          [{field, "URL must include a host"}]
        %URI{scheme: scheme} when scheme not in ["http", "https"] ->
          [{field, "URL scheme must be http or https"}]
        _ ->
          []
      end
    end)
  end
end
