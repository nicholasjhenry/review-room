defmodule MyApp.Attrs do
  @type t() :: %{required(binary()) => term()} | %{required(atom()) => term()}
end
