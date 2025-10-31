defmodule MyApp do
  @doc false
  def record do
    quote do
      use Ecto.Schema

      alias MyApp.Identifier

      import Ecto.Changeset
      import Ecto.Query, warn: false
    end
  end

  @doc false
  def context do
    quote do
      alias Ecto.Changeset

      alias MyApp.Attrs
      alias MyApp.Identifier
      alias MyApp.Repo

      alias MyApp.Accounts.Scope

      import Ecto.Query, warn: false
    end
  end

  @doc false
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
