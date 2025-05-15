defmodule Reddit.Content do
  @moduledoc """
  The Content context.
  Handles topics, links, and comments functionality.
  """

  import Ecto.Query, warn: false
  alias Reddit.Repo
  alias Reddit.Content.{Topic, Link, Comment, CommentRating}
  # alias Reddit.Accounts

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
  Gets a single link with comments and users preloaded.

  Raises `Ecto.NoResultsError` if the Link does not exist.

  ## Examples

      iex> get_link_with_comments!(123)
      %Link{}

      iex> get_link_with_comments!(456)
      ** (Ecto.NoResultsError)

  """
  def get_link_with_comments!(id) do
    # First get the link
    link = Repo.get!(Link, id)

    # Then preload associations separately
    link = link
      |> Repo.preload([:user, :topic])
      |> Repo.preload([comments: from(c in Comment, order_by: [desc: c.posted_at])])
      |> Repo.preload([comments: :user])

    # Preload scores for all comments
    %{link | comments: preload_comment_scores(link.comments)}
  end

  @doc """
  Preloads scores for a list of comments.
  If user_id is provided, also preloads the user's rating for each comment.
  """
  def preload_comment_scores(comments, user_id \\ nil) do
    # Get all comment IDs
    comment_ids = Enum.map(comments, & &1.id)

    # Get scores for all comments in a single query
    scores = from(r in CommentRating,
                 where: r.comment_id in ^comment_ids,
                 group_by: r.comment_id,
                 select: {r.comment_id, sum(r.value)})
             |> Repo.all()
             |> Map.new(fn {id, score} -> {id, score || 0} end)

    # Get user ratings if user_id is provided
    user_ratings = if user_id do
      from(r in CommentRating,
           where: r.comment_id in ^comment_ids and r.user_id == ^user_id,
           select: {r.comment_id, r.value})
      |> Repo.all()
      |> Map.new()
    else
      %{}
    end

    # Update each comment with its score and user rating
    Enum.map(comments, fn comment ->
      score = Map.get(scores, comment.id, 0)
      user_rating = Map.get(user_ratings, comment.id)
      %{comment | score: score}
      |> Map.put(:user_rating, user_rating)
    end)
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

    query =
      from l in Link,
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

    query =
      from l in Link,
        join: t in Topic,
        on: l.topic_id == t.id,
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
    # First determine if comments are loaded
    comment_count = if Ecto.assoc_loaded?(link.comments) do
      length(link.comments)
    else
      # If comments aren't loaded, query the count
      Repo.aggregate(from(c in Comment, where: c.link_id == ^link.id), :count, :id)
    end

    # Ensure user and topic are proper Ecto structs before further processing
    user_data = if Ecto.assoc_loaded?(link.user) do
      %{id: link.user.id, username: link.user.username}
    else
      %{id: nil, username: "unknown"}
    end

    topic_data = if Ecto.assoc_loaded?(link.topic) do
      %{id: link.topic.id, name: link.topic.name, slug: link.topic.slug}
    else
      %{id: nil, name: "unknown", slug: "unknown"}
    end

    # Create a new link structure without manipulating the original
    link
    |> Map.put(:comment_count, comment_count)
    |> Map.put(:user, user_data)
    |> Map.put(:topic, topic_data)
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
          list_links(limit: 25, preload_associations: true)
          # The comment_count is already added in preload_associations_for_link
          # No need to calculate it again

        # Store in cache
        Reddit.Cache.put_homepage_links(links)
        links

      cached_links ->
        # Cache hit
        cached_links
    end
  end

  @doc """
  Updates an existing link.
  Also broadcasts the update event and invalidates cache.

  ## Examples

      iex> update_link(link, %{title: "Updated Title"})
      {:ok, %Link{}}

      iex> update_link(link, %{title: ""})
      {:error, %Ecto.Changeset{}}

  """
  def update_link(%Link{} = link, attrs) do
    result =
      link
      |> Link.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated_link} ->
        # First, get a fresh copy of the link with all associations properly loaded
        link_with_assocs = Repo.get!(Link, updated_link.id) |> Repo.preload([:user, :topic])

        # Get comment count directly
        comment_count = Repo.aggregate(from(c in Comment, where: c.link_id == ^updated_link.id), :count, :id)

        # Create payload for broadcasting using the fresh data
        link_payload = %{
          id: link_with_assocs.id,
          url: link_with_assocs.url,
          title: link_with_assocs.title,
          body: link_with_assocs.body,
          posted_at: link_with_assocs.posted_at,
          score: link_with_assocs.score,
          user: %{
            id: link_with_assocs.user.id,
            username: link_with_assocs.user.username
          },
          topic: %{
            id: link_with_assocs.topic.id,
            name: link_with_assocs.topic.name,
            slug: link_with_assocs.topic.slug
          },
          comment_count: comment_count
        }

        # Broadcast the updated link
        Phoenix.PubSub.broadcast(Reddit.PubSub, "links:updated", %{
          event: "updated_link",
          payload: link_payload
        })

        # Invalidate the cache
        Reddit.Cache.delete_homepage_links()

        # Return the result with freshly loaded associations
        {:ok, link_with_assocs}

      error ->
        error
    end
  end

  @doc """
  Deletes a link.
  Also broadcasts the deletion event and invalidates cache.

  ## Examples

      iex> delete_link(link)
      {:ok, %Link{}}

      iex> delete_link(link)
      {:error, %Ecto.Changeset{}}

  """
  def delete_link(%Link{} = link) do
    result = Repo.delete(link)

    case result do
      {:ok, deleted_link} ->
        # Broadcast the deleted link id
        Phoenix.PubSub.broadcast(Reddit.PubSub, "links:deleted", %{
          event: "deleted_link",
          payload: %{id: deleted_link.id}
        })

        # Invalidate the cache
        Reddit.Cache.delete_homepage_links()

        {:ok, deleted_link}

      error ->
        error
    end
  end

  # Comment Rating functions

  @doc """
  Creates or updates a rating for a comment by a specific user.

  ## Examples

      iex> rate_comment(user_id, comment_id, 1)
      {:ok, %CommentRating{}}

      iex> rate_comment(user_id, comment_id, -1)
      {:ok, %CommentRating{}}

      iex> rate_comment(user_id, comment_id, 2)
      {:error, %Ecto.Changeset{}}
  """
  def rate_comment(user_id, comment_id, value) when value in [-1, 1] do
    # Check if rating already exists
    case Repo.get_by(CommentRating, user_id: user_id, comment_id: comment_id) do
      nil ->
        # Create new rating
        %CommentRating{}
        |> CommentRating.changeset(%{
          user_id: user_id,
          comment_id: comment_id,
          value: value
        })
        |> Repo.insert()
        |> broadcast_comment_rating_change(comment_id)

      rating ->
        if rating.value == value do
          # Delete rating if it's the same (toggle the vote off)
          Repo.delete(rating)
          |> broadcast_comment_rating_change(comment_id)
        else
          # Update rating
          rating
          |> CommentRating.changeset(%{value: value})
          |> Repo.update()
          |> broadcast_comment_rating_change(comment_id)
        end
    end
  end

  @doc """
  Gets a user's rating for a specific comment.
  Returns nil if the user hasn't rated the comment.

  ## Examples

      iex> get_comment_rating(user_id, comment_id)
      1

      iex> get_comment_rating(user_id, comment_id)
      -1

      iex> get_comment_rating(user_id, comment_id)
      nil
  """
  def get_comment_rating(user_id, comment_id) do
    case Repo.get_by(CommentRating, user_id: user_id, comment_id: comment_id) do
      nil -> nil
      rating -> rating.value
    end
  end

  @doc """
  Gets the total score for a comment (sum of all ratings).

  ## Examples

      iex> get_comment_score(comment_id)
      5
  """
  def get_comment_score(comment_id) do
    query = from r in CommentRating,
            where: r.comment_id == ^comment_id,
            select: sum(r.value)

    Repo.one(query) || 0
  end

  defp broadcast_comment_rating_change({:ok, _rating} = result, comment_id) do
    # Get updated score
    score = get_comment_score(comment_id)

    # Broadcast the updated score
    Phoenix.PubSub.broadcast(
      Reddit.PubSub,
      "comment:#{comment_id}:rated",
      %{event: "comment_rated", payload: %{id: comment_id, score: score}}
    )

    result
  end

  defp broadcast_comment_rating_change(error, _), do: error
end
