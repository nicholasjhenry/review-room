defmodule ReviewRoom.Snippets do
  @moduledoc """
  The Snippets context.
  """

  use ReviewRoom, :context

  alias ReviewRoom.Accounts.Scope
  alias ReviewRoom.Snippets.{Buffer, Snippet, SyntaxRegistry, TagCatalog}

  @buffer_fields ~w(title description body syntax tags visibility author_id)a

  @spec change_snippet(Scope.t(), Attrs.t()) :: Ecto.Changeset.t(Snippet.t())
  def change_snippet(%Scope{user: user}, attrs \\ %{}) do
    %Snippet{}
    |> Snippet.creation_changeset(attrs)
    |> Snippet.put_author_changeset(user)
  end

  @spec enqueue(Scope.t(), Attrs.t()) :: {:ok, map()} | {:error, Ecto.Changeset.t(Snippet.t())}
  def enqueue(%Scope{} = scope, attrs) when is_map(attrs) do
    changeset = change_snippet(scope, attrs)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, %Snippet{} = snippet} ->
        payload = snippet_payload(snippet)
        buffer_module().enqueue(scope, payload)

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}
    end
  end

  @spec flush_now(Scope.t()) :: :ok
  def flush_now(%Scope{} = scope) do
    buffer_module().flush_now(scope)
  end

  @doc """
  Returns the list of available syntax/language options for the snippet form.

  Returns a list of {display_name, language_key} tuples suitable for select inputs.
  """
  @spec syntax_options() :: [{String.t(), String.t()}]
  def syntax_options do
    SyntaxRegistry.options()
  end

  @doc """
  Returns the curated tag catalog for snippet categorization.

  Returns a list of {label, slug} tuples suitable for tag selection inputs.
  """
  @spec tags_catalog() :: [{String.t(), String.t()}]
  def tags_catalog do
    TagCatalog.options()
  end

  defp buffer_module do
    Application.get_env(:review_room, :snippet_buffer_module, Buffer)
  end

  defp snippet_payload(%Snippet{author: author} = snippet) do
    snippet
    |> Map.from_struct()
    |> Map.take(@buffer_fields)
    |> Map.put(:author_id, author.id)
    |> Map.update(:tags, [], fn
      nil -> []
      tags -> tags
    end)
  end
end
