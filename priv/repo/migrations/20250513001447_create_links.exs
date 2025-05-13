defmodule Reddit.Repo.Migrations.CreateLinks do
  use Ecto.Migration

  def change do
    create table(:links) do
      add :url, :text, null: false
      add :title, :string, null: false
      add :body, :text
      add :posted_at, :utc_datetime_usec, null: false
      add :score, :integer, default: 0, null: false
      add :user_id, references(:users, on_delete: :restrict), null: false
      add :topic_id, references(:topics, on_delete: :restrict), null: false

      timestamps(type: :utc_datetime_usec)
    end

    # Create indexes for faster lookups and joins
    create index(:links, [:user_id])
    create index(:links, [:topic_id])
    create index(:links, [:posted_at])
    create index(:links, [:score])
  end
end
