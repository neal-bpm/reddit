defmodule Reddit.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :body, :text, null: false
      add :posted_at, :utc_datetime_usec, null: false
      add :user_id, references(:users, on_delete: :restrict), null: false
      add :link_id, references(:links, on_delete: :delete_all), null: false
      add :parent_comment_id, references(:comments, on_delete: :nilify_all)

      timestamps(type: :utc_datetime_usec)
    end

    # Create indexes for faster lookups and joins
    create index(:comments, [:user_id])
    create index(:comments, [:link_id])
    create index(:comments, [:parent_comment_id])
    create index(:comments, [:posted_at])
  end
end
