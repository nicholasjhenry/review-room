defmodule ReviewRoomWeb.Components.DesignSystem.FormComponents do
  @moduledoc """
  Form-focused primitives that embrace the Spec 003 design tokens.

  The helpers in this module provide the hero shell, field scaffolding,
  and feedback toast required by the redesigned snippet management flows.
  """

  use ReviewRoomWeb, :html

  import ReviewRoomWeb.CoreComponents, only: [icon: 1, input: 1]

  alias Phoenix.HTML.FormField
  alias ReviewRoomWeb.CoreComponents

  @share_helper "Share the current editor context with collaborators once visibility updates propagate."

  attr :id, :string, default: "snippet-form-shell"
  attr :layout, :string, default: "balanced"
  attr :hero_id, :string, default: "snippet-form-hero"
  attr :eyebrow, :string, default: "Snippet Studio"
  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :metrics, :list, default: nil
  attr :share_label, :string, default: @share_helper
  attr :share_url, :string, default: ""
  attr :share_target_id, :string, default: "snippet-share-url"

  slot :inner_block, required: true

  def form_shell(assigns) do
    assigns =
      assigns
      |> assign(:metrics, assigns[:metrics] || default_metrics())
      |> assign_new(:share_url, fn -> "" end)
      |> assign(:hero_title_id, "#{assigns.hero_id}-title")

    ~H"""
    <section
      id={@hero_id}
      data-role="form-hero"
      class="relative isolate overflow-hidden rounded-[32px] border border-white/10 bg-gradient-to-br from-slate-950 via-slate-900 to-slate-800 px-6 py-8 text-white shadow-[0_35px_80px_rgba(15,23,42,0.45)] lg:px-10 lg:py-12"
    >
      <div
        aria-hidden="true"
        class="pointer-events-none absolute inset-0 opacity-60"
      >
        <div class="absolute -left-10 top-0 h-32 w-32 rounded-full bg-emerald-400/40 blur-[80px]" />
        <div class="absolute bottom-0 right-0 h-48 w-48 rounded-full bg-sky-400/30 blur-[120px]" />
      </div>
      <div class="space-y-6">
        <p class="text-[0.65rem] uppercase tracking-[0.65em] text-white/60">{@eyebrow}</p>
        <div class="space-y-3">
          <h1
            id={@hero_title_id}
            class="text-4xl font-semibold leading-tight tracking-tight sm:text-5xl"
          >
            {@title}
          </h1>
          <p :if={@description} class="text-base text-white/80 sm:text-lg">{@description}</p>
        </div>
      </div>

      <dl class="mt-8 grid gap-4 md:grid-cols-3">
        <div
          :for={metric <- @metrics}
          data-role="form-metric"
          class="rounded-2xl border border-white/20 bg-white/5 p-4 shadow-lg shadow-slate-950/30"
        >
          <dt class="text-xs uppercase tracking-[0.35em] text-white/60">
            {metric[:label]}
          </dt>
          <dd class="mt-2 text-2xl font-semibold text-white">
            {metric[:value]}
          </dd>
        </div>
      </dl>

      <div class="mt-8 flex flex-wrap items-center gap-4">
        <div
          id="snippet-share-toolbar"
          phx-hook="ClipboardCopy"
          data-clipboard-target={"##{@share_target_id}"}
          data-state="default"
          class="inline-flex items-center gap-2 rounded-full border border-white/25 bg-white/10 px-4 py-2 text-sm font-semibold text-white backdrop-blur"
        >
          <span data-default-state class="flex items-center gap-2">
            <.icon name="hero-link" class="h-4 w-4" /> Copy share URL
          </span>
          <span data-success-state class="hidden items-center gap-2 text-emerald-300">
            <.icon name="hero-check" class="h-4 w-4" /> Copied
          </span>
          <span data-error-state class="hidden items-center gap-2 text-rose-200">
            <.icon name="hero-exclamation-triangle" class="h-4 w-4" /> Retry
          </span>
        </div>
        <p class="text-xs text-white/70">
          {@share_label}
        </p>
      </div>
      <p id={@share_target_id} class="sr-only" aria-hidden="true">
        {@share_url}
      </p>
    </section>

    <div
      id={@id}
      data-layout={@layout}
      class="mt-8 grid gap-8 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)] xl:gap-10"
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :field, FormField, required: true
  attr :label, :string, required: true
  attr :helper, :string, default: nil

  attr :input_type, :string,
    default: "text",
    values: ~w(text textarea select email number password url tel)

  attr :prompt, :string, default: nil
  attr :options, :list, default: []
  attr :rows, :any, default: nil
  attr :input_class, :string, default: nil
  attr :required, :boolean, default: false
  attr :rest, :global

  def field(assigns) do
    field_key = field_key(assigns.field)

    assigns =
      assigns
      |> assign(:field_key, field_key)
      |> assign(:helper_id, "field-#{field_key}-helper")
      |> assign(:error_id, "field-#{field_key}-error")
      |> assign(:errors, translate_field_errors(assigns.field))

    assigns = assign(assigns, :aria_describedby, aria_describedby(assigns))

    ~H"""
    <div
      data-role="form-field"
      data-field={@field_key}
      class="rounded-2xl border border-slate-200/70 bg-white/95 p-5 shadow-sm shadow-slate-200/60"
    >
      <div class="flex flex-wrap items-baseline justify-between gap-2">
        <label for={@field.id} class="text-sm font-semibold text-slate-900">
          {@label}
        </label>
        <span
          :if={@required}
          class="inline-flex items-center rounded-full bg-slate-900/5 px-2.5 py-0.5 text-xs font-semibold uppercase tracking-wide text-slate-500"
        >
          Required
        </span>
      </div>

      <div class="mt-4 space-y-3">
        <.input
          field={@field}
          type={@input_type}
          prompt={@prompt}
          options={@options}
          rows={@rows}
          aria-describedby={@aria_describedby}
          class={@input_class || input_classes(@input_type)}
          {@rest}
        />

        <p
          :if={@helper}
          id={@helper_id}
          data-role="field-helper"
          data-field={@field_key}
          class="flex items-center gap-2 text-sm leading-relaxed text-slate-500"
        >
          <.icon name="hero-sparkles" class="h-4 w-4 text-amber-500" />
          {@helper}
        </p>

        <p
          :if={@errors != []}
          id={@error_id}
          data-role="field-error"
          data-field={@field_key}
          class="flex items-center gap-2 rounded-lg bg-rose-50 px-3 py-2 text-sm font-medium text-rose-600"
        >
          <.icon name="hero-exclamation-circle" class="h-4 w-4" />
          {Enum.map_join(@errors, " ", fn msg -> "#{@label} #{msg}" end)}
        </p>
      </div>
    </div>
    """
  end

  attr :id, :string, default: "snippet-form-toast"
  attr :flash, :map, default: %{}
  attr :kind, :atom, default: :info
  attr :message, :string, default: nil
  attr :auto_dismiss_ms, :integer, default: 4200

  def feedback_toast(assigns) do
    assigns =
      assigns
      |> assign_new(:message, fn -> Phoenix.Flash.get(assigns.flash, assigns.kind) end)
      |> assign(:visible?, !!assigns.message)
      |> assign(:visibility_attr, if(assigns.message, do: "visible", else: "hidden"))

    ~H"""
    <section
      id={@id}
      role="status"
      aria-live="polite"
      data-reduced-motion-target="form-toast"
      data-visibility={@visibility_attr}
      data-motion="standard"
      phx-hook="FormFeedbackToast"
      data-auto-dismiss-ms={@auto_dismiss_ms}
      class="col-span-full"
    >
      <div
        class={[
          "flex items-center justify-between gap-4 rounded-2xl border border-emerald-200/60 bg-emerald-50 px-4 py-3 text-sm text-emerald-900 shadow-sm shadow-emerald-200/50 transition",
          @visible? || "opacity-0 pointer-events-none"
        ]}
        data-role="toast-surface"
      >
        <div class="flex flex-1 items-start gap-3">
          <div class="rounded-full bg-emerald-100 p-1 text-emerald-600">
            <.icon name="hero-check-circle" class="h-5 w-5" />
          </div>
          <div>
            <p class="font-semibold">Success</p>
            <p>{@message || "Updates will display here once you save the form."}</p>
          </div>
        </div>
        <button
          type="button"
          data-action="dismiss"
          phx-click="dismiss_toast"
          class="inline-flex items-center gap-2 rounded-full border border-emerald-200 px-3 py-1.5 text-xs font-semibold text-emerald-700 transition hover:bg-emerald-100"
        >
          Dismiss
        </button>
      </div>
    </section>
    """
  end

  defp translate_field_errors(%FormField{} = field) do
    if Phoenix.Component.used_input?(field) do
      Enum.map(field.errors, &CoreComponents.translate_error/1)
    else
      []
    end
  end

  defp field_key(%FormField{field: field}) when is_atom(field), do: Atom.to_string(field)

  defp aria_describedby(assigns) do
    [assigns.helper_id, assigns.error_id]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  defp input_classes("textarea"),
    do:
      "min-h-[280px] w-full rounded-2xl border border-slate-200 bg-slate-50/60 px-4 py-3 font-mono text-sm text-slate-900 shadow-inner shadow-white/40 focus:border-slate-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-slate-900/10"

  defp input_classes(_type),
    do:
      "w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-900 shadow-sm transition focus:border-slate-900 focus:outline-none focus:ring-2 focus:ring-slate-900/10"

  defp default_metrics do
    [
      %{label: "Quality review", value: "WCAG AA ready"},
      %{label: "Motion budget", value: "< 180ms transitions"}
    ]
  end
end
