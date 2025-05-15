defmodule Reddit.Content.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :body, :string
    field :posted_at, :utc_datetime_usec
    field :score, :integer, virtual: true, default: 0
    field :user_rating, :integer, virtual: true

    belongs_to :user, Reddit.Accounts.User, foreign_key: :user_id
    belongs_to :link, Reddit.Content.Link, foreign_key: :link_id
    belongs_to :parent_comment, __MODULE__, foreign_key: :parent_comment_id
    has_many :replies, __MODULE__, foreign_key: :parent_comment_id
    has_many :ratings, Reddit.Content.CommentRating, foreign_key: :comment_id

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :user_id, :link_id, :parent_comment_id, :posted_at])
    |> validate_required([:body, :user_id, :link_id, :posted_at])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:link_id)
    |> foreign_key_constraint(:parent_comment_id)
  end
end
