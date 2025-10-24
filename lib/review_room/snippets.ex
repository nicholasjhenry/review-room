defmodule ReviewRoom.Snippets do
  @moduledoc """
  The Snippets context - boundary for snippet operations.
  """

  import Ecto.Query, warn: false
  alias ReviewRoom.Accounts.{Scope, User}
  alias ReviewRoom.Repo
  alias ReviewRoom.Snippets.Snippet

  @gallery_default_limit 20
  @gallery_max_limit 50

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
  Lists public snippets for the discovery gallery.
  """
  @spec list_public_snippets(keyword()) :: [Snippet.t()]
  def list_public_snippets(opts \\ []) do
    opts = normalize_gallery_opts(opts)

    Snippet
    |> public_scope(opts.language)
    |> apply_cursor(opts.cursor)
    |> order_and_limit(opts.limit)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Searches public snippets by title and description terms.
  """
  @spec search_snippets(String.t(), keyword()) :: [Snippet.t()]
  def search_snippets(query_string, opts \\ [])

  def search_snippets(query_string, opts) when is_binary(query_string) do
    trimmed = String.trim(query_string)
    opts = normalize_gallery_opts(opts)

    if trimmed == "" do
      list_public_snippets(opts)
    else
      pattern = "%#{escape_like(trimmed)}%"

      Snippet
      |> public_scope(opts.language)
      |> where(
        [s],
        fragment("COALESCE(?, '') ILIKE ? ESCAPE '\\'", s.title, ^pattern) or
          fragment("COALESCE(?, '') ILIKE ? ESCAPE '\\'", s.description, ^pattern)
      )
      |> apply_cursor(opts.cursor)
      |> order_and_limit(opts.limit)
      |> preload(:user)
      |> Repo.all()
    end
  end

  def search_snippets(_query, opts), do: list_public_snippets(opts)

  @doc """
  Returns the list of supported languages for snippet filters.
  """
  @spec supported_languages() :: [String.t()]
  def supported_languages do
    Snippet.supported_languages()
    |> Enum.reject(&is_nil/1)
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

  defp normalize_gallery_opts(opts) do
    limit =
      opts
      |> Keyword.get(:limit, @gallery_default_limit)
      |> clamp_limit()

    language =
      opts
      |> Keyword.get(:language)
      |> normalize_language()

    cursor =
      opts
      |> Keyword.get(:cursor)
      |> normalize_cursor()

    %{limit: limit, language: language, cursor: cursor}
  end

  defp clamp_limit(limit) when is_integer(limit) and limit > 0 do
    min(limit, @gallery_max_limit)
  end

  defp clamp_limit(_), do: @gallery_default_limit

  defp normalize_language(language) when language in [nil, ""], do: nil

  defp normalize_language(language) when is_atom(language) do
    language
    |> Atom.to_string()
    |> normalize_language()
  end

  defp normalize_language(language) when is_binary(language) do
    normalized = language |> String.trim() |> String.downcase()

    if normalized in supported_languages() do
      normalized
    else
      nil
    end
  end

  defp normalize_language(_), do: nil

  defp normalize_cursor(nil), do: nil

  defp normalize_cursor({%DateTime{} = dt, id}) when is_binary(id) do
    {DateTime.truncate(dt, :second), id}
  end

  defp normalize_cursor({%NaiveDateTime{} = dt, id}) when is_binary(id) do
    dt
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.truncate(:second)
    |> then(&{&1, id})
  end

  defp normalize_cursor({inserted_at, id}) when is_binary(id) do
    case normalize_cursor(inserted_at) do
      nil -> nil
      {dt, _} -> {dt, id}
    end
  end

  defp normalize_cursor(%DateTime{} = dt), do: {DateTime.truncate(dt, :second), ""}

  defp normalize_cursor(%NaiveDateTime{} = dt) do
    dt
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.truncate(:second)
    |> then(&{&1, ""})
  end

  defp normalize_cursor(binary) when is_binary(binary) do
    case String.split(binary, "::", parts: 2) do
      [iso, id] ->
        with {:ok, dt, 0} <- DateTime.from_iso8601(iso) do
          {DateTime.truncate(dt, :second), id}
        else
          _ -> nil
        end

      [iso] ->
        with {:ok, dt, 0} <- DateTime.from_iso8601(iso) do
          {DateTime.truncate(dt, :second), ""}
        else
          _ -> nil
        end
    end
  end

  defp normalize_cursor(_), do: nil

  defp public_scope(query, language) do
    query = from s in query, where: s.visibility == :public

    if language do
      from s in query, where: s.language == ^language
    else
      query
    end
  end

  defp apply_cursor(query, nil), do: query

  defp apply_cursor(query, {cursor_dt, ""}) do
    from s in query, where: s.inserted_at < ^cursor_dt
  end

  defp apply_cursor(query, {cursor_dt, cursor_id}) do
    from s in query,
      where:
        s.inserted_at < ^cursor_dt or
          (s.inserted_at == ^cursor_dt and s.id < ^cursor_id)
  end

  defp order_and_limit(query, limit) do
    from s in query,
      order_by: [desc: s.inserted_at, desc: s.id],
      limit: ^limit
  end

  defp escape_like(term) do
    term
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end
end
