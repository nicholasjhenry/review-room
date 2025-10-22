defmodule ReviewRoom.SnippetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ReviewRoom.Snippets` context.
  """

  @doc """
  Generate a snippet.
  """
  def snippet_fixture(attrs \\ %{}) do
    {:ok, snippet} =
      attrs
      |> Enum.into(%{
        code: "def hello, do: :world",
        title: "Example Snippet",
        description: "A test snippet",
        language: "elixir",
        visibility: :private
      })
      |> ReviewRoom.Snippets.create_snippet()

    snippet
  end

  @doc """
  Generate a snippet with a specific user.
  """
  def snippet_fixture_with_user(user, attrs \\ %{}) do
    {:ok, snippet} =
      attrs
      |> Enum.into(%{
        code: "def hello, do: :world",
        title: "Example Snippet",
        description: "A test snippet",
        language: "elixir",
        visibility: :private
      })
      |> ReviewRoom.Snippets.create_snippet(user)

    snippet
  end
end
