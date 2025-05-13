defmodule Reddit.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    has_many :links, Reddit.Content.Link, foreign_key: :user_id
    has_many :comments, Reddit.Content.Comment, foreign_key: :user_id
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_required([:username])
    |> unique_constraint(:username)
  end
end
