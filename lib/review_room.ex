defmodule ReviewRoom do
  @moduledoc """
  ReviewRoom keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  @doc false
  def record do
    quote do
      use Ecto.Schema

      alias ReviewRoom.Attrs

      import Ecto.Changeset
      import Ecto.Query, warn: false
    end
  end

  @doc false
  def context do
    quote do
      alias Ecto.Changeset

      alias ReviewRoom.Attrs
      alias ReviewRoom.Identifier
      alias ReviewRoom.Repo

      alias ReviewRoom.Accounts.Scope

      import Ecto.Query, warn: false
    end
  end

  @doc false
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
