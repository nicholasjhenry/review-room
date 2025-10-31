defmodule ReviewRoom.Snippets.SyntaxRegistry do
  @moduledoc """
  Provides a curated list of supported syntax/language options for code snippets.

  This module maintains a compile-time map of language identifiers to their
  display names, consumed by LiveView forms and changeset validations.
  """

  @type language_key :: String.t()
  @type display_name :: String.t()

  @doc """
  Returns the complete map of supported languages.
  """
  @spec all() :: %{language_key() => display_name()}
  def all do
    %{
      "elixir" => "Elixir",
      "erlang" => "Erlang",
      "javascript" => "JavaScript",
      "typescript" => "TypeScript",
      "python" => "Python",
      "ruby" => "Ruby",
      "rust" => "Rust",
      "go" => "Go",
      "java" => "Java",
      "kotlin" => "Kotlin",
      "swift" => "Swift",
      "csharp" => "C#",
      "cpp" => "C++",
      "c" => "C",
      "php" => "PHP",
      "sql" => "SQL",
      "html" => "HTML",
      "css" => "CSS",
      "bash" => "Bash",
      "shell" => "Shell",
      "yaml" => "YAML",
      "json" => "JSON",
      "xml" => "XML",
      "markdown" => "Markdown",
      "plaintext" => "Plain Text"
    }
  end

  @doc """
  Returns a list of {display_name, language_key} tuples suitable for select inputs.
  """
  @spec options() :: [{display_name(), language_key()}]
  def options do
    all()
    |> Enum.map(fn {key, display} -> {display, key} end)
    |> Enum.sort_by(fn {display, _key} -> display end)
  end

  @doc """
  Checks if a given language key is supported.
  """
  @spec supported?(language_key()) :: boolean()
  def supported?(language_key) when is_binary(language_key) do
    Map.has_key?(all(), language_key)
  end

  def supported?(_), do: false

  @doc """
  Returns the display name for a given language key.
  """
  @spec display_name(language_key()) :: {:ok, display_name()} | {:error, :not_found}
  def display_name(language_key) when is_binary(language_key) do
    case Map.fetch(all(), language_key) do
      {:ok, display} -> {:ok, display}
      :error -> {:error, :not_found}
    end
  end

  def display_name(_), do: {:error, :not_found}

  @doc """
  Returns the default language key to use when none is specified.
  """
  @spec default() :: language_key()
  def default, do: "plaintext"
end
