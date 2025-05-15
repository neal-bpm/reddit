defmodule Reddit.Content.CommentRating do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comment_ratings" do
    field :value, :integer
    belongs_to :user, Reddit.Accounts.User
    belongs_to :comment, Reddit.Content.Comment

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(comment_rating, attrs) do
    comment_rating
    |> cast(attrs, [:value, :user_id, :comment_id])
    |> validate_required([:value, :user_id, :comment_id])
    |> validate_inclusion(:value, [-1, 1], message: "must be either -1 (downvote) or 1 (upvote)")
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:comment_id)
    |> unique_constraint([:user_id, :comment_id], message: "User has already voted on this comment")
  end
end
