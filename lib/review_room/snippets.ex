defmodule ReviewRoom.Snippets do
  @moduledoc """
  The Snippets context - boundary for snippet operations.
  """

  import Ecto.Query, warn: false
  alias ReviewRoom.Accounts.{Scope, User}
  alias ReviewRoom.Repo
  alias ReviewRoom.Snippets.Snippet

  @doc """
  Creates a snippet.

  ## Examples

      iex> create_snippet(%{code: "def hello, do: :world"})
      {:ok, %Snippet{}}

      iex> create_snippet(%{})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_snippet(map()) :: {:ok, Snippet.t()} | {:error, Ecto.Changeset.t()}
  def create_snippet(attrs) when is_map(attrs) do
    create_snippet(nil, attrs)
  end

  @spec create_snippet(Scope.t() | User.t() | nil, map()) ::
          {:ok, Snippet.t()} | {:error, Ecto.Changeset.t()}
  def create_snippet(scope, attrs) when is_map(attrs) do
    %Snippet{}
    |> Snippet.create_changeset(attrs, scope_user(scope))
    |> Repo.insert()
  end

  @doc """
  Gets a single snippet.

  Raises `Ecto.NoResultsError` if the Snippet does not exist.

  ## Examples

      iex> get_snippet!("abc12345")
      %Snippet{}

      iex> get_snippet!("invalid")
      ** (Ecto.NoResultsError)

  """
  @spec get_snippet!(String.t()) :: Snippet.t()
  def get_snippet!(id) do
    Repo.get!(Snippet, id)
  end

  @doc """
  Gets a single snippet, returns nil if not found.

  ## Examples

      iex> get_snippet("abc12345")
      %Snippet{}

      iex> get_snippet("invalid")
      nil

  """
  @spec get_snippet(String.t()) :: Snippet.t() | nil
  def get_snippet(id) do
    Repo.get(Snippet, id)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking snippet changes.

  ## Examples

      iex> change_snippet(snippet)
      %Ecto.Changeset{data: %Snippet{}}

  """
  @spec change_snippet(Snippet.t(), map()) :: Ecto.Changeset.t()
  def change_snippet(%Snippet{} = snippet, attrs \\ %{}) do
    Snippet.create_changeset(snippet, attrs)
  end

  @doc """
  Updates a snippet if the given user is authorized.
  """
  @spec update_snippet(Scope.t() | nil, Snippet.t(), map()) ::
          {:ok, Snippet.t()} | {:error, Ecto.Changeset.t() | :unauthorized}
  def update_snippet(scope, %Snippet{} = snippet, attrs) do
    with :ok <- authorize_edit(snippet, scope),
         changeset <- Snippet.update_changeset(snippet, attrs),
         {:ok, updated} <- Repo.update(changeset) do
      {:ok, Repo.preload(updated, :user)}
    else
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
      {:error, :unauthorized} = error -> error
    end
  end

  @doc """
  Deletes a snippet if the given user is authorized.
  """
  @spec delete_snippet(Scope.t() | nil, Snippet.t()) ::
          {:ok, Snippet.t()} | {:error, :unauthorized}
  def delete_snippet(scope, %Snippet{} = snippet) do
    with :ok <- authorize_delete(snippet, scope),
         {:ok, deleted} <- Repo.delete(snippet) do
      {:ok, deleted}
    else
      {:error, :unauthorized} = error -> error
    end
  end

  @doc """
  Lists snippets that belong to the given user id.
  """
  @spec list_user_snippets(Scope.t() | User.t() | binary() | nil, keyword()) :: [Snippet.t()]
  def list_user_snippets(scope_or_user, opts \\ [])

  def list_user_snippets(%Scope{} = scope, opts), do: list_user_snippets(scope_user(scope), opts)

  def list_user_snippets(%User{id: user_id}, opts), do: list_user_snippets(user_id, opts)

  def list_user_snippets(nil, _opts), do: []

  def list_user_snippets(user_id, opts) when is_binary(user_id) do
    limit = Keyword.get(opts, :limit, 50)

    Snippet
    |> where([s], s.user_id == ^user_id)
    |> order_by([s], desc: s.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Toggles a snippet's visibility between :public and :private.
  """
  @spec toggle_visibility(Scope.t() | nil, Snippet.t()) ::
          {:ok, Snippet.t()} | {:error, Ecto.Changeset.t() | :unauthorized}
  def toggle_visibility(scope, %Snippet{} = snippet) do
    new_visibility =
      case snippet.visibility do
        :public -> :private
        _ -> :public
      end

    update_snippet(scope, snippet, %{visibility: new_visibility})
  end

  @doc """
  Returns true if the given user can edit the snippet.
  """
  @spec can_edit?(Scope.t() | User.t() | nil, Snippet.t()) :: boolean()
  def can_edit?(_scope, %Snippet{user_id: nil}), do: false

  def can_edit?(scope, %Snippet{} = snippet),
    do: scope_user(scope) |> matches_snippet_owner?(snippet)

  @doc """
  Returns true if the given user can delete the snippet.
  """
  @spec can_delete?(Scope.t() | User.t() | nil, Snippet.t()) :: boolean()
  def can_delete?(scope, snippet), do: can_edit?(scope, snippet)

  defp authorize_edit(snippet, scope) do
    if can_edit?(scope, snippet), do: :ok, else: {:error, :unauthorized}
  end

  defp authorize_delete(snippet, scope), do: authorize_edit(snippet, scope)

  defp scope_user(%Scope{user: %User{} = user}), do: user
  defp scope_user(%User{} = user), do: user
  defp scope_user(_), do: nil

  defp matches_snippet_owner?(%User{id: user_id}, %Snippet{user_id: user_id}), do: true
  defp matches_snippet_owner?(_, _), do: false
end
