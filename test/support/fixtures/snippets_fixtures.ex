defmodule ReviewRoom.SnippetsFixtures do
  @moduledoc """
  Test fixtures for creating snippet test data.
  """

  alias ReviewRoom.Snippets

  @doc """
  Generate a snippet with valid attributes.
  """
  def snippet_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        title: "Test Snippet",
        description: "A test snippet description",
        code: "IO.puts(\"Hello, World!\")",
        language: "elixir",
        visibility: :private,
        tags: []
      })

    {:ok, snippet} = Snippets.create_snippet(attrs, scope)
    snippet
  end

  @doc """
  Generate multiple snippets for testing list operations.
  """
  def create_snippets(scope, count \\ 3) do
    Enum.map(1..count, fn i ->
      snippet_fixture(scope, %{
        title: "Snippet #{i}",
        code: "# Code for snippet #{i}"
      })
    end)
  end
end
