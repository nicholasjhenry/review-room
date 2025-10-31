defmodule ReviewRoom.SnippetsFixtures do
  @moduledoc """
  Test helpers for creating snippet records.
  """

  alias ReviewRoom.Snippets

  import ReviewRoom.AccountsFixtures, only: [user_scope_fixture: 0]

  def snippet_attrs(attrs \\ %{}) do
    Enum.into(attrs, %{
      code: "IO.puts(:example)",
      language: "elixir",
      visibility: "private",
      title: "Example snippet",
      description: "Example description",
      tags: ["example"]
    })
  end

  def snippet_fixture(scope \\ user_scope_fixture(), attrs \\ %{}) do
    attrs = snippet_attrs(attrs)

    Snippets.create_snippet(scope, attrs)
    |> case do
      {:ok, snippet} -> snippet
      {:error, changeset} -> raise "snippet_fixture error: #{inspect(changeset.errors)}"
    end
  end
end
