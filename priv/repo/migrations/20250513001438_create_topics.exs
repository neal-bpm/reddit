defmodule Reddit.Repo.Migrations.CreateTopics do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text

      timestamps(type: :utc_datetime_usec)
    end

    # Create unique indexes on name and slug
    create unique_index(:topics, [:name])
    create unique_index(:topics, [:slug])
  end
end
