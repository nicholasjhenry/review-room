defmodule ReviewRoomWeb.SnippetLive.Components do
  use ReviewRoomWeb, :html

  alias ReviewRoom.Snippets.Snippet
  alias ReviewRoomWeb.Components.DesignSystem.FormComponents
  alias ReviewRoomWeb.SnippetLive.FormContext

  @code_input_class "min-h-[360px] w-full rounded-3xl border border-slate-200/80 bg-slate-50/70 px-4 py-3 font-mono text-sm text-slate-900 shadow-inner shadow-white/60 focus:border-slate-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-slate-900/10"
  @share_helper "Share the current editor context with collaborators once visibility updates propagate."

  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :form, :any, required: true
  attr :flash, :map, default: %{}
  attr :snippet, Snippet, default: %Snippet{}
  attr :layout, :string, default: "balanced"
  attr :share_label, :string, default: nil
  attr :share_url, :any, default: ""
  attr :guidance_panels, :list, default: []
  attr :safety_pulses, :list, default: []
  attr :share_target_id, :string, default: "snippet-share-url"
  attr :id, :string, default: "snippet-form"
  attr :change_event, :string, default: "validate"
  attr :submit_event, :string, default: "save"
  attr :submit_label, :string, default: "Save changes"
  attr :submit_disable_with, :string, default: "Saving..."
  attr :cancel_href, :any, required: true
  attr :show_delete?, :boolean, default: false
  attr :delete_button_id, :string, default: nil
  attr :delete_event, :string, default: nil
  attr :delete_confirm, :string, default: "Delete this snippet permanently?"
  attr :delete_disable_with, :string, default: "Deleting..."
  attr :button_class, :string, default: ""

  def snippet_form(assigns) do
    assigns =
      assigns
      |> assign_new(:guidance_panels, fn -> [] end)
      |> assign_new(:safety_pulses, fn -> [] end)
      |> assign_new(:share_label, fn -> @share_helper end)

    ~H"""
    <FormComponents.form_shell
      id="snippet-form-shell"
      hero_id="snippet-form-hero"
      layout={@layout}
      title={@title}
      description={@description}
      share_label={@share_label}
      share_url={@share_url}
      share_target_id={@share_target_id}
    >
      <section class="rounded-[32px] border border-slate-100/80 bg-white/95 p-6 shadow-[0_25px_60px_rgba(15,23,42,0.08)] lg:p-8">
        <.form
          for={@form}
          id={@id}
          phx-change={@change_event}
          phx-submit={@submit_event}
          class="space-y-6"
          aria-labelledby="snippet-form-hero-title"
        >
          <FormComponents.field
            field={@form[:code]}
            label="Code"
            helper="Paste or compose your snippet. We highlight syntax automatically."
            required
            input_type="textarea"
            rows="18"
            input_class={code_input_class()}
            phx-debounce="300"
          />

          <div class="grid gap-5 md:grid-cols-2">
            <FormComponents.field
              field={@form[:title]}
              label="Title"
              helper="Displayed in galleries, feeds, and share sheets."
            />

            <FormComponents.field
              field={@form[:language]}
              label="Language"
              helper="Override auto-detect when linters need a specific target."
              input_type="select"
              prompt="Auto-detect"
              options={FormContext.language_options()}
            />
          </div>

          <FormComponents.field
            field={@form[:description]}
            label="Description"
            helper="Provide collaboration context, acceptance criteria, or review notes."
            input_type="textarea"
            rows="4"
          />

          <FormComponents.field
            field={@form[:visibility]}
            label="Visibility"
            helper="Control discoverability across the public gallery and direct links."
            input_type="select"
            required
            options={FormContext.visibility_options()}
          />

          <div class="flex flex-wrap items-center gap-4">
            <.button
              type="submit"
              phx-disable-with={@submit_disable_with}
              class={primary_button_class(@button_class)}
            >
              <.icon name="hero-code-bracket" class="h-4 w-4" />
              {@submit_label}
            </.button>

            <.link
              navigate={@cancel_href}
              class="inline-flex items-center gap-2 rounded-full border border-slate-200 px-5 py-2.5 text-sm font-semibold text-slate-600 transition hover:border-slate-300 hover:text-slate-900"
            >
              Cancel
            </.link>

            <button
              :if={@show_delete?}
              type="button"
              id={@delete_button_id}
              phx-click={@delete_event}
              phx-value-id={@snippet.id}
              phx-disable-with={@delete_disable_with}
              phx-confirm={@delete_confirm}
              class="inline-flex items-center gap-2 rounded-full border border-rose-200/70 bg-rose-50 px-5 py-2.5 text-sm font-semibold text-rose-700 transition hover:bg-rose-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-rose-400"
            >
              <.icon name="hero-trash" class="h-4 w-4" /> Delete snippet
            </button>
          </div>
        </.form>

        <FormComponents.feedback_toast flash={@flash} />
      </section>

      <aside class="space-y-5">
        <div
          :for={panel <- @guidance_panels}
          id={"panel-#{panel.id}"}
          class="rounded-3xl border border-slate-200/80 bg-white/90 p-5 shadow-sm"
        >
          <div class="flex items-start justify-between gap-3">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.35em] text-slate-400">
                {panel.title}
              </p>
              <p class="mt-1 text-sm text-slate-500">
                {panel.description}
              </p>
            </div>
            <span class="inline-flex items-center rounded-full bg-slate-900/5 px-3 py-1 text-xs font-semibold text-slate-600">
              Live
            </span>
          </div>

          <dl class="mt-4 space-y-3">
            <div
              :for={row <- panel.rows}
              class="flex items-center justify-between text-sm text-slate-600"
            >
              <dt>{row.label}</dt>
              <dd class={["font-semibold text-slate-900", row[:accent]]}>{row.value}</dd>
            </div>
          </dl>
        </div>

        <div
          :if={@safety_pulses != []}
          class="rounded-3xl border border-slate-900/30 bg-slate-900 px-5 py-6 text-white shadow-2xl shadow-slate-900/50"
        >
          <div class="flex items-center justify-between">
            <p class="text-xs font-semibold uppercase tracking-[0.35em] text-white/60">
              Status pulses
            </p>
            <span class="text-xs font-medium text-white/60">Auto-updating</span>
          </div>

          <div class="mt-5 space-y-4">
            <div
              :for={pulse <- @safety_pulses}
              class="flex items-center justify-between gap-3 text-sm text-white/90"
            >
              <div class="flex items-center gap-3">
                <span class={["inline-flex h-2.5 w-2.5 rounded-full", pulse_accent(pulse.tone)]} />
                <span class="font-medium">{pulse.label}</span>
              </div>
              <span class="text-xs uppercase tracking-wider text-white/60">
                {pulse.value}
              </span>
            </div>
          </div>
        </div>
      </aside>
    </FormComponents.form_shell>
    """
  end

  defp pulse_accent(:success), do: "bg-emerald-400"
  defp pulse_accent(:info), do: "bg-sky-300"
  defp pulse_accent(:neutral), do: "bg-white/60"
  defp pulse_accent(_), do: "bg-white/40"

  defp code_input_class, do: @code_input_class

  defp primary_button_class(extra) do
    base =
      "inline-flex items-center justify-center gap-2 rounded-full bg-slate-900 px-6 py-3 text-sm font-semibold text-white shadow-lg shadow-slate-900/30 transition hover:-translate-y-0.5 hover:bg-slate-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-900/30"

    String.trim("#{base} #{extra || ""}")
  end
end
