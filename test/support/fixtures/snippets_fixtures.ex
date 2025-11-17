defmodule ReviewRoom.SnippetsFixtures do
  alias ReviewRoom.Snippets

  def snippet_fixture(scope, attrs \\ []) do
    attrs =
      Enum.into(attrs, %{
        title: "Test Snippet #{System.unique_integer([:positive])}",
        code: "defmodule Test do\n  def hello, do: :world\nend",
        language: "elixir",
        visibility: "private",
        tags: []
      })

    {:ok, snippet} = Snippets.create_snippet(scope, attrs)
    snippet
  end

  def public_snippet_fixture(scope, attrs \\ []) do
    attrs = Enum.into(attrs, %{})

    attrs
    |> Map.put(:visibility, "public")
    |> then(&snippet_fixture(scope, &1))
  end

  def tagged_snippet_fixture(scope, attrs \\ []) do
    attrs = Enum.into(attrs, %{})

    attrs
    |> Map.put(:tags, "elixir,test")
    |> then(&snippet_fixture(scope, &1))
  end
end
