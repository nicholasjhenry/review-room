defmodule ReviewRoom.Snippets.TagCatalog do
  @moduledoc """
  Provides a curated catalog of suggested tags for code snippets.

  This module loads tag definitions from application configuration and
  exposes validation and selection helpers for the LiveView UI.

  Tags are stored as a simple list in configuration and can be managed
  by product operations without code changes.
  """

  @type tag_slug :: String.t()
  @type tag_entry :: %{slug: tag_slug(), label: String.t(), color: String.t() | nil}

  @doc """
  Returns the complete list of curated tag entries.

  Reads from application config :review_room, :snippet_tags or falls back
  to a default set if not configured.
  """
  @spec all() :: [tag_entry()]
  def all do
    Application.get_env(:review_room, :snippet_tags, default_tags())
  end

  @doc """
  Returns a list of tag slugs only, suitable for validation.
  """
  @spec slugs() :: [tag_slug()]
  def slugs do
    all()
    |> Enum.map(& &1.slug)
  end

  @doc """
  Returns a list of {label, slug} tuples suitable for select inputs.
  """
  @spec options() :: [{String.t(), tag_slug()}]
  def options do
    all()
    |> Enum.map(fn %{slug: slug, label: label} -> {label, slug} end)
    |> Enum.sort_by(fn {label, _slug} -> label end)
  end

  @doc """
  Checks if a given tag slug is in the catalog.

  Note: This is optional validation. The system may allow free-form tags
  depending on configuration.
  """
  @spec valid?(tag_slug()) :: boolean()
  def valid?(tag_slug) when is_binary(tag_slug) do
    tag_slug in slugs()
  end

  def valid?(_), do: false

  @doc """
  Validates a list of tag slugs against the catalog.

  Returns :ok if all tags are valid, or {:error, invalid_tags} if any are not.
  """
  @spec validate_all([tag_slug()]) :: :ok | {:error, [tag_slug()]}
  def validate_all(tags) when is_list(tags) do
    invalid = Enum.reject(tags, &valid?/1)

    case invalid do
      [] -> :ok
      invalid_tags -> {:error, invalid_tags}
    end
  end

  @doc """
  Normalizes a tag string: trims whitespace and converts to lowercase.
  """
  @spec normalize(String.t()) :: tag_slug()
  def normalize(tag) when is_binary(tag) do
    tag
    |> String.trim()
    |> String.downcase()
  end

  @doc """
  Normalizes and deduplicates a list of tag strings.
  """
  @spec normalize_list([String.t()]) :: [tag_slug()]
  def normalize_list(tags) when is_list(tags) do
    tags
    |> Enum.map(&normalize/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  # Default tag catalog when not configured
  defp default_tags do
    [
      %{slug: "algorithm", label: "Algorithm", color: nil},
      %{slug: "api", label: "API", color: nil},
      %{slug: "authentication", label: "Authentication", color: nil},
      %{slug: "cli", label: "CLI", color: nil},
      %{slug: "database", label: "Database", color: nil},
      %{slug: "debugging", label: "Debugging", color: nil},
      %{slug: "deployment", label: "Deployment", color: nil},
      %{slug: "error-handling", label: "Error Handling", color: nil},
      %{slug: "frontend", label: "Frontend", color: nil},
      %{slug: "http", label: "HTTP", color: nil},
      %{slug: "performance", label: "Performance", color: nil},
      %{slug: "security", label: "Security", color: nil},
      %{slug: "testing", label: "Testing", color: nil},
      %{slug: "ui", label: "UI", color: nil},
      %{slug: "utility", label: "Utility", color: nil},
      %{slug: "validation", label: "Validation", color: nil},
      %{slug: "web", label: "Web", color: nil}
    ]
  end
end
