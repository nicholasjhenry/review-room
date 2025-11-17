defmodule ReviewRoom.Snippets do
  @moduledoc """
  Context for managing code snippets.
  """
  use ReviewRoom, :context

  import Ecto.Query, warn: false
  alias ReviewRoom.Repo
  alias ReviewRoom.Snippets.Snippet

  @spec list_snippets(Scope.t(), keyword()) :: [Snippet.t()]
  def list_snippets(scope, opts \\ []) do
    Snippet
    |> where([s], s.user_id == ^scope.user.id)
    |> filter_by_tag(opts)
    |> order_by([s], desc: s.inserted_at)
    |> Repo.all()
  end

  @spec list_public_snippets(keyword()) :: [Snippet.t()]
  def list_public_snippets(opts \\ []) do
    Snippet
    |> where([s], s.visibility == :public)
    |> filter_by_tag(opts)
    |> order_by([s], desc: s.inserted_at)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  @spec get_snippet(Scope.t(), String.t()) :: {:ok, Snippet.t()} | {:error, :not_found}
  def get_snippet(scope, slug) do
    query =
      Snippet
      |> where([s], s.slug == ^slug)

    query =
      if scope.user do
        user_id = scope.user.id

        where(
          query,
          [s],
          s.visibility == :public or s.visibility == :unlisted or
            (s.visibility == :private and s.user_id == ^user_id)
        )
      else
        where(query, [s], s.visibility == :public or s.visibility == :unlisted)
      end

    case Repo.one(query) do
      nil -> {:error, :not_found}
      snippet -> {:ok, snippet}
    end
  end

  @spec create_snippet(Scope.t(), Attrs.t()) ::
          {:ok, Snippet.t()} | {:error, Ecto.Changeset.t(Snippet.t())}
  def create_snippet(scope, attrs) do
    # Parse comma-separated tags if provided as string
    attrs_with_tags = parse_tags(attrs)

    %Snippet{user_id: scope.user.id}
    |> Snippet.changeset(attrs_with_tags)
    |> Repo.insert()
  end

  @spec update_snippet(Scope.t(), Snippet.t(), Attrs.t()) ::
          {:ok, Snippet.t()} | {:error, Ecto.Changeset.t(Snippet.t())} | {:error, :unauthorized}
  def update_snippet(scope, snippet, attrs) do
    if snippet.user_id == scope.user.id do
      attrs_with_tags = parse_tags(attrs)

      snippet
      |> Snippet.changeset(attrs_with_tags)
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  @spec delete_snippet(Scope.t(), Snippet.t()) ::
          {:ok, Snippet.t()} | {:error, Ecto.Changeset.t(Snippet.t())} | {:error, :unauthorized}
  def delete_snippet(scope, snippet) do
    if snippet.user_id == scope.user.id do
      Repo.delete(snippet)
    else
      {:error, :unauthorized}
    end
  end

  @spec change_snippet(Snippet.t(), Attrs.t()) :: Ecto.Changeset.t(Snippet.t())
  def change_snippet(snippet, attrs \\ %{}) do
    Snippet.changeset(snippet, attrs)
  end

  @spec list_all_tags() :: [String.t()]
  def list_all_tags do
    from(s in Snippet,
      select: fragment("unnest(?)", s.tags),
      distinct: true,
      order_by: fragment("unnest(?)", s.tags)
    )
    |> Repo.all()
  end

  @spec supported_languages() :: [String.t()]
  def supported_languages do
    Application.get_env(:review_room, :supported_languages, [])
  end

  # Private helpers

  defp filter_by_tag(query, opts) do
    case Keyword.get(opts, :tag) do
      nil -> query
      tag when is_binary(tag) -> where(query, [s], ^tag in s.tags)
      _ -> query
    end
  end

  defp parse_tags(attrs) do
    case attrs do
      %{"tags" => tags} when is_binary(tags) ->
        tag_list =
          tags
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))

        Map.put(attrs, "tags", tag_list)

      %{"tags" => tags} when is_list(tags) ->
        attrs

      %{tags: tags} when is_binary(tags) ->
        tag_list =
          tags
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))

        Map.put(attrs, :tags, tag_list)

      _ ->
        attrs
    end
  end
end
