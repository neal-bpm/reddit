defmodule Reddit.Repo.Migrations.CreateCommentRatings do
  use Ecto.Migration

  def change do
    create table(:comment_ratings) do
      add :value, :integer, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :comment_id, references(:comments, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:comment_ratings, [:user_id])
    create index(:comment_ratings, [:comment_id])
    create unique_index(:comment_ratings, [:user_id, :comment_id], name: :user_comment_unique_rating)
  end
end
