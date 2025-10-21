defmodule ReviewRoom.Snippets do
  @moduledoc """
  The Snippets context - boundary for snippet operations.
  """

  import Ecto.Query, warn: false
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
end
