defmodule ReviewRoom.Snippets do
  @moduledoc """
  The Snippets context - boundary for snippet operations.
  """

  import Ecto.Query, warn: false
  alias ReviewRoom.Accounts.User
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
  @spec create_snippet(map(), ReviewRoom.Accounts.User.t() | nil) ::
          {:ok, Snippet.t()} | {:error, Ecto.Changeset.t()}
  def create_snippet(attrs, user \\ nil) do
    %Snippet{}
    |> Snippet.create_changeset(attrs, user)
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
  @spec update_snippet(Snippet.t(), map(), User.t() | nil) ::
          {:ok, Snippet.t()} | {:error, Ecto.Changeset.t() | :unauthorized}
  def update_snippet(%Snippet{} = snippet, attrs, user) do
    with :ok <- authorize_edit(snippet, user),
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
  @spec delete_snippet(Snippet.t(), User.t() | nil) ::
          {:ok, Snippet.t()} | {:error, :unauthorized}
  def delete_snippet(%Snippet{} = snippet, user) do
    with :ok <- authorize_delete(snippet, user),
         {:ok, deleted} <- Repo.delete(snippet) do
      {:ok, deleted}
    else
      {:error, :unauthorized} = error -> error
    end
  end

  @doc """
  Lists snippets that belong to the given user id.
  """
  @spec list_user_snippets(binary(), keyword()) :: [Snippet.t()]
  def list_user_snippets(user_id, opts \\ []) do
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
  @spec toggle_visibility(Snippet.t(), User.t() | nil) ::
          {:ok, Snippet.t()} | {:error, Ecto.Changeset.t() | :unauthorized}
  def toggle_visibility(%Snippet{} = snippet, user) do
    new_visibility =
      case snippet.visibility do
        :public -> :private
        _ -> :public
      end

    update_snippet(snippet, %{visibility: new_visibility}, user)
  end

  @doc """
  Returns true if the given user can edit the snippet.
  """
  @spec can_edit?(Snippet.t(), User.t() | nil) :: boolean()
  def can_edit?(%Snippet{user_id: nil}, _user), do: false
  def can_edit?(%Snippet{user_id: user_id}, %User{id: user_id}), do: true
  def can_edit?(_, _), do: false

  @doc """
  Returns true if the given user can delete the snippet.
  """
  @spec can_delete?(Snippet.t(), User.t() | nil) :: boolean()
  def can_delete?(snippet, user), do: can_edit?(snippet, user)

  defp authorize_edit(snippet, user) do
    if can_edit?(snippet, user), do: :ok, else: {:error, :unauthorized}
  end

  defp authorize_delete(snippet, user), do: authorize_edit(snippet, user)
end
