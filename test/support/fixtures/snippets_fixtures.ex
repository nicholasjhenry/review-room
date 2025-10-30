defmodule ReviewRoom.SnippetsFixtures do
  @moduledoc """
  Test helpers for creating snippet data scoped to authenticated users.
  """

  alias ReviewRoom.Accounts.Scope
  alias ReviewRoom.AccountsFixtures

  @default_title "Refactoring Phoenix contexts"
  @default_description "Notes on re-organising contexts for better ownership."
  @default_body """
  def hydrate_scope(socket, scope) do
    assign(socket, current_scope: scope)
  end
  """

  def scope_fixture do
    AccountsFixtures.user_fixture()
    |> Scope.for_user()
  end

  def scope_fixture(user) do
    Scope.for_user(user)
  end

  def valid_snippet_attrs(attrs \\ %{}) do
    defaults = %{
      "title" => @default_title,
      "description" => @default_description,
      "body" => @default_body,
      "syntax" => "elixir",
      "tags" => ["phoenix", "liveview"],
      "visibility" => "personal"
    }

    Map.merge(defaults, attrs)
  end
end
