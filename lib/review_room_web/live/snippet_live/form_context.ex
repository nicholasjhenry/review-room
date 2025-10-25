defmodule ReviewRoomWeb.SnippetLive.FormContext do
  @moduledoc """
  Shared helpers for Spec 003 snippet form assignments.

  Provides language/visibility options, side panel datasets, and preview helpers
  so both the new and edit LiveViews stay perfectly aligned with the design system.
  """

  alias ReviewRoom.Snippets.Snippet

  @language_options [
    {"Elixir", "elixir"},
    {"Erlang", "erlang"},
    {"JavaScript", "javascript"},
    {"TypeScript", "typescript"},
    {"Python", "python"},
    {"Ruby", "ruby"},
    {"Go", "go"},
    {"Rust", "rust"},
    {"Java", "java"},
    {"Kotlin", "kotlin"},
    {"Swift", "swift"},
    {"C", "c"},
    {"C++", "cpp"},
    {"C#", "csharp"},
    {"PHP", "php"},
    {"SQL", "sql"},
    {"HTML", "html"},
    {"CSS", "css"},
    {"SCSS", "scss"},
    {"JSON", "json"},
    {"YAML", "yaml"},
    {"Markdown", "markdown"},
    {"Shell", "shell"},
    {"Bash", "bash"},
    {"Dockerfile", "dockerfile"},
    {"XML", "xml"},
    {"Plain Text", "plaintext"}
  ]

  @visibility_options [
    {"Private — link only", :private},
    {"Public — discoverable", :public}
  ]

  @type panel_row :: %{label: String.t(), value: String.t(), accent: String.t() | nil}

  @doc "Options for the language select field."
  @spec language_options() :: [{String.t(), String.t()}]
  def language_options, do: @language_options

  @doc "Visibility dropdown options."
  @spec visibility_options() :: [{String.t(), atom()}]
  def visibility_options, do: @visibility_options

  @doc """
  Generates guidance panels shown on the right rail.
  """
  @spec guidance_panels(Snippet.t()) :: [map()]
  def guidance_panels(%Snippet{} = snippet) do
    [
      %{
        id: "publishing-checklist",
        title: "Publishing checklist",
        description: "Guardrails before broadcasting updates.",
        rows: [
          %{label: "Visibility", value: visibility_label(snippet), accent: "text-emerald-600"},
          %{label: "Language", value: language_label(snippet)},
          %{label: "Last updated", value: updated_label(snippet)}
        ]
      },
      %{
        id: "delivery-quality",
        title: "Delivery quality",
        description: "Signals monitored as collaborators join.",
        rows: [
          %{label: "Accessibility", value: "AA contrast locked"},
          %{label: "Motion budget", value: "<180ms micro-interactions"},
          %{label: "Sync status", value: sync_label(snippet)}
        ]
      }
    ]
  end

  @doc """
  Returns pulse indicators visualised as subtle timelines.
  """
  @spec safety_pulses(Snippet.t()) :: [map()]
  def safety_pulses(%Snippet{} = snippet) do
    [
      %{label: "WCAG contrast", value: "AA met", tone: :success},
      %{label: "Syntax checks", value: syntax_label(snippet), tone: :info},
      %{label: "Visibility sync", value: "#{visibility_label(snippet)} ready", tone: :neutral}
    ]
  end

  @doc """
  Builds a temporary snippet struct reflecting current form params.
  """
  @spec preview_snippet(Snippet.t(), map()) :: Snippet.t()
  def preview_snippet(%Snippet{} = snippet, params) when is_map(params) do
    Enum.reduce(params, snippet, fn
      {"visibility", value}, acc ->
        Map.put(acc, :visibility, normalize_visibility(value, acc.visibility))

      {"language", value}, acc ->
        Map.put(acc, :language, normalize_blank(value))

      {"title", value}, acc ->
        Map.put(acc, :title, value)

      {"description", value}, acc ->
        Map.put(acc, :description, value)

      _other, acc ->
        acc
    end)
  end

  defp visibility_label(%Snippet{visibility: nil}), do: "Private draft"
  defp visibility_label(%Snippet{visibility: :public}), do: "Public"
  defp visibility_label(%Snippet{visibility: :private}), do: "Private"
  defp visibility_label(_snippet), do: "Draft"

  defp language_label(%Snippet{language: nil}), do: "Auto-detect"

  defp language_label(%Snippet{language: value}) do
    Enum.find_value(@language_options, "Auto-detect", fn {label, option_value} ->
      if option_value == value, do: label
    end)
  end

  defp updated_label(%Snippet{updated_at: nil}), do: "Draft moments ago"

  defp updated_label(%Snippet{updated_at: updated_at}) do
    updated_at
    |> DateTime.shift_zone!("Etc/UTC")
    |> Calendar.strftime("%b %-d • %H:%M UTC")
  rescue
    _ -> "Recently synced"
  end

  defp sync_label(%Snippet{visibility: :public}), do: "Live in gallery"
  defp sync_label(%Snippet{visibility: :private}), do: "Shared securely"
  defp sync_label(_snippet), do: "Pending visibility"

  defp syntax_label(%Snippet{code: code}) when is_binary(code) do
    if String.trim(code) == "" do
      "Waiting for content"
    else
      "Syntax highlight ready"
    end
  end

  defp syntax_label(_snippet), do: "Waiting for content"

  defp normalize_visibility("public", _default), do: :public
  defp normalize_visibility("private", _default), do: :private
  defp normalize_visibility(value, _default) when value in [:public, :private], do: value
  defp normalize_visibility(_value, default), do: default

  defp normalize_blank(value) when value in [nil, ""], do: nil
  defp normalize_blank(value), do: value
end
