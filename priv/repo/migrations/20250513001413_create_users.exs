defmodule Reddit.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    # Create a unique index on the username for faster lookups and to enforce uniqueness
    create unique_index(:users, [:username])
  end
end
