defmodule ReviewRoom.SnippetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ReviewRoom.Snippets` context.
  """

  alias ReviewRoom.Accounts.Scope

  @doc """
  Generate a snippet.
  """
  def snippet_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        code: "def hello, do: :world",
        title: "Example Snippet",
        description: "A test snippet",
        language: "elixir",
        visibility: :private
      })

    {:ok, snippet} = ReviewRoom.Snippets.create_snippet(attrs)

    snippet
  end

  @doc """
  Generate a snippet with a specific user.
  """
  def snippet_fixture_with_user(user, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        code: "def hello, do: :world",
        title: "Example Snippet",
        description: "A test snippet",
        language: "elixir",
        visibility: :private
      })

    {:ok, snippet} = ReviewRoom.Snippets.create_snippet(Scope.for_user(user), attrs)

    snippet
  end
end
