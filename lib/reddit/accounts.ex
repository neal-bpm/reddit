defmodule Reddit.Accounts do
  @moduledoc """
  The Accounts context.
  Handles user-related functionality.
  """

  import Ecto.Query, warn: false
  alias Reddit.Repo
  alias Reddit.Accounts.User

  @doc """
  Gets a user by ID.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      nil

  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a user by username.

  ## Examples

      iex> get_user_by_username("johndoe")
      %User{}

      iex> get_user_by_username("nonexistent")
      nil

  """
  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
  end

  @doc """
  Finds a user by username or creates a new one if not found.

  ## Examples

      iex> find_or_create_user_by_username(%{username: "johndoe"})
      {:ok, %User{}}

      iex> find_or_create_user_by_username(%{username: ""})
      {:error, %Ecto.Changeset{}}

  """
  def find_or_create_user_by_username(%{username: username} = attrs) when is_binary(username) do
    case get_user_by_username(username) do
      nil -> create_user(attrs)
      user -> {:ok, user}
    end
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{username: "johndoe"})
      {:ok, %User{}}

      iex> create_user(%{username: ""})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end
