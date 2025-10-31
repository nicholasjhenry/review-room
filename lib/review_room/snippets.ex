defmodule ReviewRoom.Snippets do
  @moduledoc """
  Context for managing code snippets.
  """
  use ReviewRoom, :context

  alias ReviewRoom.Snippets.Snippet

  ## Snippet Creation & Updates

  @doc """
  Creates a new snippet for the given user scope.
  """
  @spec create_snippet(Scope.t(), Attrs.t()) ::
          {:ok, Snippet.t()} | {:error, Ecto.Changeset.t(Snippet.t())}
  def create_snippet(%Scope{user: user}, attrs) do
    %Snippet{}
    |> Snippet.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Returns a changeset for tracking snippet changes (validation only, no DB).
  Used by LiveView for real-time validation without persistence.
  """
  @spec change_snippet(Snippet.t(), Attrs.t()) :: Ecto.Changeset.t(Snippet.t())
  def change_snippet(%Snippet{} = snippet, attrs \\ %{}) do
    Snippet.changeset(snippet, attrs)
  end

  ## Snippet Retrieval

  @doc """
  Gets a single snippet by ID with authorization check.
  Returns the snippet if the current user is authorized to view it.
  Returns nil if not found or not authorized.
  """
  @spec get_snippet(Scope.t(), Identifier.t()) :: Snippet.t() | nil
  def get_snippet(%Scope{user: user}, id) do
    Snippet
    |> where([s], s.id == ^id)
    |> where([s], s.user_id == ^user.id or s.visibility == "public")
    |> preload(:user)
    |> Repo.one()
  end

  @doc """
  Lists all snippets accessible to the current user.
  Includes user's own snippets and public snippets from others.
  """
  @spec list_snippets(Scope.t()) :: [Snippet.t()]
  def list_snippets(%Scope{user: user}) do
    Snippet
    |> where([s], s.user_id == ^user.id or s.visibility == "public")
    |> order_by([s], desc: s.inserted_at)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Lists snippets for the current user only.
  """
  @spec list_my_snippets(Scope.t()) :: [Snippet.t()]
  def list_my_snippets(%Scope{user: user}) do
    Snippet
    |> where([s], s.user_id == ^user.id)
    |> order_by([s], desc: s.inserted_at)
    |> Repo.all()
  end

  @doc """
  Lists all unique tags used across all snippets.
  """
  @spec list_all_tags() :: [String.t()]
  def list_all_tags do
    query =
      from s in Snippet,
        select: fragment("unnest(?)", s.tags)

    Repo.all(query)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Lists snippets that have a specific tag.
  """
  @spec list_snippets_by_tag(Scope.t(), String.t()) :: [Snippet.t()]
  def list_snippets_by_tag(%Scope{user: user}, tag_name) do
    Snippet
    |> where([s], s.user_id == ^user.id or s.visibility == "public")
    |> where([s], fragment("? = ANY(?)", ^tag_name, s.tags))
    |> order_by([s], desc: s.inserted_at)
    |> preload(:user)
    |> Repo.all()
  end
end
