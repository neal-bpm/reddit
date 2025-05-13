defmodule Reddit.Content do
  @moduledoc """
  The Content context.
  Handles topics, links, and comments functionality.
  """

  import Ecto.Query, warn: false
  alias Reddit.Repo
  alias Reddit.Content.{Topic, Link, Comment}
  alias Reddit.Accounts

  # Topic-related functions

  @doc """
  Returns a list of all topics.

  ## Examples

      iex> list_topics()
      [%Topic{}, ...]

  """
  def list_topics do
    Repo.all(Topic)
  end

  @doc """
  Creates a new topic.

  ## Examples

      iex> create_topic(%{name: "Elixir", slug: "elixir", description: "Programming with Elixir"})
      {:ok, %Topic{}}

      iex> create_topic(%{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  def create_topic(attrs) do
    %Topic{}
    |> Topic.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a topic by its slug.

  ## Examples

      iex> get_topic_by_slug("elixir")
      %Topic{}

      iex> get_topic_by_slug("nonexistent")
      nil

  """
  def get_topic_by_slug(slug) when is_binary(slug) do
    Repo.get_by(Topic, slug: slug)
  end

  @doc """
  Gets a topic by ID.

  ## Examples

      iex> get_topic(123)
      %Topic{}

      iex> get_topic(456)
      nil

  """
  def get_topic(id), do: Repo.get(Topic, id)

  @doc """
  Returns a changeset for tracking topic changes.

  ## Examples

      iex> change_topic(topic)
      %Ecto.Changeset{data: %Topic{}}

  """
  def change_topic(%Topic{} = topic, attrs \\ %{}) do
    Topic.changeset(topic, attrs)
  end

  # Link-related functions

  @doc """
  Returns a changeset for tracking link changes.

  ## Examples

      iex> change_link(link)
      %Ecto.Changeset{data: %Link{}}

  """
  def change_link(%Link{} = link, attrs \\ %{}) do
    Link.changeset(link, attrs)
  end

  @doc """
  Creates a new link.
  Also broadcasts link creation event and invalidates cache.

  ## Examples

      iex> create_link(%{url: "https://example.com", title: "Example", user_id: 1, topic_id: 1})
      {:ok, %Link{}}

      iex> create_link(%{url: ""})
      {:error, %Ecto.Changeset{}}

  """
  def create_link(attrs) do
    result =
      %Link{posted_at: DateTime.utc_now()}
      |> Link.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, link} ->
        # Preload associations for the broadcast payload
        preloaded_link =
          link
          |> Repo.preload([:user, :topic])

        # Create payload for broadcasting
        link_payload = %{
          id: link.id,
          url: link.url,
          title: link.title,
          body: link.body,
          posted_at: link.posted_at,
          score: link.score,
          user: %{id: preloaded_link.user.id, username: preloaded_link.user.username},
          topic: %{
            id: preloaded_link.topic.id,
            name: preloaded_link.topic.name,
            slug: preloaded_link.topic.slug
          },
          comment_count: 0
        }

        # Broadcast the new link
        Phoenix.PubSub.broadcast(Reddit.PubSub, "links:new", %{
          event: "new_link",
          payload: link_payload
        })

        # Invalidate the cache
        Reddit.Cache.delete_homepage_links()

        {:ok, link}

      error ->
        error
    end
  end

  @doc """
  Gets a link by ID.

  ## Examples

      iex> get_link!(123)
      %Link{}

      iex> get_link!(456)
      ** (Ecto.NoResultsError)

  """
  def get_link!(id), do: Repo.get!(Link, id)

  @doc """
  Gets a link by ID with preloaded comments, user, and topic.

  ## Examples

      iex> get_link_with_comments!(123)
      %Link{comments: [%Comment{},...], user: %User{}, topic: %Topic{}}

  """
  def get_link_with_comments!(id) do
    Link
    |> Repo.get!(id)
    |> Repo.preload([
      :user,
      :topic,
      comments: {Comment |> order_by([c], asc: c.posted_at), :user}
    ])
  end

  @doc """
  Lists links with pagination, sorted by posted_at descending.

  ## Options

    * `:page` - Page number (starting with 1)
    * `:per_page` - Number of links per page
    * `:preload_associations` - Boolean, whether to preload user and topic

  ## Examples

      iex> list_links(page: 1, per_page: 20)
      [%Link{}, ...]

  """
  def list_links(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)
    preload = Keyword.get(opts, :preload_associations, false)

    query = from l in Link,
      order_by: [desc: l.posted_at],
      limit: ^per_page,
      offset: ^((page - 1) * per_page)

    links = Repo.all(query)

    if preload do
      preload_associations_for_link(links)
    else
      links
    end
  end

  @doc """
  Lists links for a given topic slug with pagination, sorted by posted_at descending.

  ## Options

    * `:page` - Page number (starting with 1)
    * `:per_page` - Number of links per page
    * `:preload_associations` - Boolean, whether to preload user and topic

  ## Examples

      iex> list_links_by_topic_slug("elixir", page: 1, per_page: 20)
      [%Link{}, ...]

  """
  def list_links_by_topic_slug(topic_slug, opts \\ []) when is_binary(topic_slug) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)
    preload = Keyword.get(opts, :preload_associations, false)

    query = from l in Link,
      join: t in Topic, on: l.topic_id == t.id,
      where: t.slug == ^topic_slug,
      order_by: [desc: l.posted_at],
      limit: ^per_page,
      offset: ^((page - 1) * per_page)

    links = Repo.all(query)

    if preload do
      preload_associations_for_link(links)
    else
      links
    end
  end

  @doc """
  Preloads user, topic, and comments (with users) for links.

  ## Examples

      iex> preload_associations_for_link(link)
      %Link{user: %User{}, topic: %Topic{}, comment_count: 5}

  """
  def preload_associations_for_link(links) when is_list(links) do
    links
    |> Repo.preload([:user, :topic, comments: :user])
    |> Enum.map(&process_link_for_display/1)
  end

  def preload_associations_for_link(link) do
    link
    |> Repo.preload([:user, :topic, comments: :user])
    |> process_link_for_display()
  end

  defp process_link_for_display(link) do
    %{link |
      comment_count: length(link.comments),
      user: Map.take(link.user, [:id, :username]),
      topic: Map.take(link.topic, [:id, :name, :slug])
    }
    |> Map.drop([:comments])
  end

  # Comment-related functions

  @doc """
  Returns a changeset for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{data: %Comment{}}

  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  @doc """
  Creates a new comment.
  Also broadcasts comment creation event.

  ## Examples

      iex> create_comment(%{body: "Great post!", user_id: 1, link_id: 1})
      {:ok, %Comment{}}

      iex> create_comment(%{body: ""})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs) do
    result =
      %Comment{posted_at: DateTime.utc_now()}
      |> Comment.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, comment} ->
        # Preload user for the broadcast payload
        preloaded_comment = Repo.preload(comment, :user)

        # Create payload for broadcasting
        comment_payload = %{
          id: comment.id,
          body: comment.body,
          posted_at: comment.posted_at,
          link_id: comment.link_id,
          parent_comment_id: comment.parent_comment_id,
          user: %{id: preloaded_comment.user.id, username: preloaded_comment.user.username}
        }

        # Broadcast the new comment
        Phoenix.PubSub.broadcast(Reddit.PubSub, "comments:#{comment.link_id}:new", %{
          event: "new_comment",
          payload: comment_payload
        })

        {:ok, comment}

      error ->
        error
    end
  end

  @doc """
  Lists comments for a specific link, preloaded with users, sorted by posted_at.

  ## Examples

      iex> list_comments_for_link(1)
      [%Comment{user: %User{}, ...}, ...]

  """
  def list_comments_for_link(link_id) do
    Comment
    |> where([c], c.link_id == ^link_id)
    |> order_by([c], asc: c.posted_at)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Returns the homepage links, potentially from cache.
  Uses ETS-based caching for performance.

  ## Examples

      iex> list_homepage_links()
      [%Link{}, ...]

  """
  def list_homepage_links() do
    case Reddit.Cache.get_homepage_links() do
      nil ->
        # Cache miss
        links =
          list_links(preload_associations: true)
          |> Enum.take(25)  # Take top 25 for homepage

        # Store in cache
        Reddit.Cache.put_homepage_links(links)
        links

      cached_links ->
        # Cache hit
        cached_links
    end
  end
end
