defmodule ReviewRoom.Snippets do
  @moduledoc """
  The Snippets context.
  """

  alias ReviewRoom.Accounts.Scope
  alias ReviewRoom.Snippets.{Buffer, Snippet}

  @buffer_fields ~w(title description body syntax tags visibility author_id)a

  @spec change_snippet(Scope.t(), map()) :: Ecto.Changeset.t()
  def change_snippet(%Scope{user: user}, attrs \\ %{}) do
    %Snippet{}
    |> Snippet.creation_changeset(
      attrs
      |> normalize_params()
      |> Map.put("author_id", user.id)
    )
  end

  @spec enqueue(Scope.t(), map()) :: {:ok, map()} | {:error, term()}
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

  defp buffer_module do
    Application.get_env(:review_room, :snippet_buffer_module, Buffer)
  end

  defp normalize_params(attrs) do
    Enum.reduce(attrs, %{}, fn
      {key, value}, acc when is_atom(key) ->
        Map.put(acc, Atom.to_string(key), value)

      {key, value}, acc when is_binary(key) ->
        Map.put(acc, key, value)
    end)
  end

  defp snippet_payload(%Snippet{} = snippet) do
    snippet
    |> Map.from_struct()
    |> Map.take(@buffer_fields)
    |> Map.update(:tags, [], fn
      nil -> []
      tags -> tags
    end)
  end
end
