defmodule ReviewRoom.Snippets do
  @moduledoc """
  Context for managing code snippets and tags.
  """

  import Ecto.Query
  alias ReviewRoom.Repo
  alias ReviewRoom.Snippets.Snippet
  alias ReviewRoom.Accounts.Scope

  ## Snippet CRUD Operations

  @doc """
  Lists all snippets for the current user based on scope.
  """
  @spec list_snippets(Scope.t()) :: [Snippet.t()]
  def list_snippets(%Scope{user: user}) when not is_nil(user) do
    Snippet
    |> where([s], s.user_id == ^user.id)
    |> order_by([s], desc: s.inserted_at)
    |> Repo.all()
  end

  @doc """
  Lists snippets filtered by tag.
  Uses PostgreSQL array contains operator for efficient tag filtering.
  """
  @spec list_snippets_by_tag(String.t(), Scope.t()) :: [Snippet.t()]
  def list_snippets_by_tag(tag_name, %Scope{user: user}) when not is_nil(user) do
    normalized_tag = String.downcase(tag_name)

    Snippet
    |> where([s], s.user_id == ^user.id)
    |> where([s], fragment("? = ANY(?)", ^normalized_tag, s.tags))
    |> order_by([s], desc: s.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single snippet, checking visibility permissions.
  Raises `Ecto.NoResultsError` if not found or not authorized.
  """
  @spec get_snippet!(binary(), Scope.t()) :: Snippet.t()
  def get_snippet!(id, scope) do
    Snippet
    |> Repo.get!(id)
    |> check_visibility(scope)
  end

  @doc """
  Creates a snippet for the current user.
  """
  @spec create_snippet(map(), Scope.t()) :: {:ok, Snippet.t()} | {:error, Ecto.Changeset.t()}
  def create_snippet(attrs, %Scope{user: user}) when not is_nil(user) do
    %Snippet{user_id: user.id}
    |> Snippet.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a snippet owned by the current user.
  """
  @spec update_snippet(Snippet.t(), map(), Scope.t()) ::
          {:ok, Snippet.t()} | {:error, Ecto.Changeset.t() | :unauthorized}
  def update_snippet(snippet, attrs, %Scope{user: user}) when not is_nil(user) do
    if snippet.user_id == user.id do
      snippet
      |> Snippet.changeset(attrs)
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a snippet owned by the current user.
  """
  @spec delete_snippet(Snippet.t(), Scope.t()) ::
          {:ok, Snippet.t()} | {:error, Ecto.Changeset.t() | :unauthorized}
  def delete_snippet(snippet, %Scope{user: user}) when not is_nil(user) do
    if snippet.user_id == user.id do
      Repo.delete(snippet)
    else
      {:error, :unauthorized}
    end
  end

  ## Tag Operations

  @doc """
  Lists all unique tags used by the current user's snippets.
  Returns a sorted list of tag strings.
  """
  @spec list_user_tags(Scope.t()) :: [String.t()]
  def list_user_tags(%Scope{user: user}) when not is_nil(user) do
    Snippet
    |> where([s], s.user_id == ^user.id)
    |> select([s], s.tags)
    |> Repo.all()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  ## Helpers

  @doc """
  Returns an empty changeset for a new snippet.
  """
  @spec change_snippet(Snippet.t(), map()) :: Ecto.Changeset.t()
  def change_snippet(snippet, attrs \\ %{}) do
    Snippet.changeset(snippet, attrs)
  end

  # Private Functions

  defp check_visibility(snippet, nil) do
    # Guest user (not logged in) - can only view public snippets
    if snippet.visibility == :public do
      snippet
    else
      raise Ecto.NoResultsError, queryable: Snippet
    end
  end

  defp check_visibility(snippet, %Scope{user: user}) do
    cond do
      snippet.visibility == :public -> snippet
      snippet.visibility == :unlisted -> snippet
      user && snippet.user_id == user.id -> snippet
      true -> raise Ecto.NoResultsError, queryable: Snippet
    end
  end
end
