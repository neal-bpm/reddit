# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Reddit.Repo.insert!(%Reddit.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Reddit.Content
alias Reddit.Repo
alias Reddit.Content.Topic

# Clear existing topics (comment out if you don't want to remove existing topics)
Repo.delete_all(Topic)

# Create initial topics
topics = [
  %{name: "Elixir", slug: "elixir", description: "Discussions about the Elixir programming language"},
  %{name: "Phoenix", slug: "phoenix", description: "Everything related to the Phoenix web framework"},
  %{name: "Technology", slug: "technology", description: "General technology discussions"},
  %{name: "Science", slug: "science", description: "Scientific news and discussions"},
  %{name: "Gaming", slug: "gaming", description: "Video games, board games, and more"},
  %{name: "Movies", slug: "movies", description: "Film discussions, reviews, and news"},
  %{name: "Books", slug: "books", description: "Book recommendations and literary discussions"},
  %{name: "Music", slug: "music", description: "Music discussions, recommendations, and news"},
  %{name: "Sports", slug: "sports", description: "Sports news and discussions"},
  %{name: "Cooking", slug: "cooking", description: "Recipes, cooking techniques, and food discussions"}
]

for topic_attrs <- topics do
  Content.create_topic(topic_attrs)
  |> case do
    {:ok, topic} -> IO.puts("Created topic: #{topic.name}")
    {:error, changeset} -> IO.puts("Error creating topic: #{inspect(changeset.errors)}")
  end
end
