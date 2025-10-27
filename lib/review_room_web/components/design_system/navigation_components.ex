defmodule ReviewRoomWeb.Components.DesignSystem.NavigationComponents do
  @moduledoc """
  Chrome and navigation components that implement the Spec 003 visual system.

  These helpers provide the primary app shell, contextual page headers, and
  empty-state/skeleton building blocks consumed by workspace-oriented LiveViews.
  """

  use ReviewRoomWeb, :html

  import ReviewRoomWeb.CoreComponents, only: [icon: 1]

  @primary_defaults %{
    active_item: :discover
  }

  @doc """
  Renders the global navigation chrome, including brand, primary navigation,
  and user controls.

  Pass slots for additional action controls (e.g., theme toggle).
  """
  attr :current_scope, :map, default: nil
  attr :active_item, :atom, default: :discover
  attr :class, :string, default: nil

  slot :actions, doc: "Optional action controls rendered on the right-hand side."

  def primary_shell(assigns) do
    assigns =
      assigns
      |> assign_new(:current_scope, fn -> nil end)
      |> assign_new(:active_item, fn -> @primary_defaults.active_item end)
      |> assign_new(:class, fn -> nil end)

    user = nav_user(assigns.current_scope)
    nav_items = nav_items(assigns.active_item, !!user)

    assigns =
      assigns
      |> assign(:user, user)
      |> assign(:nav_items, nav_items)
      |> assign(:has_actions?, assigns.actions != [])

    ~H"""
    <header
      id="app-navigation"
      class={[
        "app-navigation relative z-40 border-b border-slate-200/70 bg-white/80 backdrop-blur-xl transition-shadow duration-200 ease-out",
        @class
      ]}
    >
      <div class="mx-auto flex max-w-6xl items-center justify-between px-4 py-4 sm:px-6 lg:px-8">
        <div class="flex items-center gap-8">
          <.link
            navigate={~p"/"}
            class="group inline-flex items-center gap-3 text-slate-900 transition hover:text-slate-950"
          >
            <img
              src={~p"/images/logo.svg"}
              alt="ReviewRoom logo"
              width="36"
              height="36"
              class="h-9 w-9 rounded-2xl border border-white/70 shadow-[0_12px_30px_-16px_rgba(15,23,42,0.35)] ring-2 ring-white/60 transition group-hover:scale-105"
            />
            <span class="text-base font-semibold tracking-tight">ReviewRoom</span>
          </.link>

          <nav
            class="hidden items-center gap-2 text-sm font-semibold md:flex"
            aria-label="Primary navigation"
          >
            <.link
              :for={item <- @nav_items}
              navigate={item.href}
              data-nav-item={Atom.to_string(item.id)}
              data-active={to_string(item.active?)}
              data-disabled={to_string(item.disabled?)}
              aria-current={item.active? && "page"}
              aria-disabled={item.disabled?}
              class={[
                "group inline-flex items-center gap-2 rounded-full px-3.5 py-2 text-slate-600 transition motion-duration-fast motion-ease-standard hover:text-slate-900",
                item.active? &&
                  "bg-slate-900 text-white shadow-[0_18px_42px_-26px_rgba(15,23,42,0.65)]",
                item.disabled? && "pointer-events-none opacity-40"
              ]}
            >
              <.icon name={item.icon} class={nav_icon_class(item.active?)} />
              <span>{item.label}</span>
            </.link>
          </nav>
        </div>

        <div class="flex items-center gap-3">
          <%= if @has_actions? do %>
            <div class="hidden items-center gap-2 md:flex">
              {render_slot(@actions)}
            </div>
          <% end %>

          <.link
            :if={!@user}
            navigate={~p"/users/log-in"}
            class="inline-flex items-center gap-2 rounded-full border border-slate-200 px-4 py-1.5 text-sm font-semibold text-slate-700 transition hover:border-slate-300 hover:text-slate-900"
          >
            <.icon name="hero-arrow-right-on-rectangle" class="h-4 w-4" /> Sign in
          </.link>

          <div
            :if={@user}
            class="inline-flex items-center gap-3 rounded-full border border-slate-200 bg-white/90 px-3 py-1.5 shadow-sm transition hover:border-slate-300"
          >
            <span
              class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-slate-900 text-sm font-semibold text-white shadow-inner"
              aria-hidden="true"
            >
              {@user.initials}
            </span>
            <div class="hidden flex-col text-left text-xs font-medium leading-tight text-slate-600 sm:flex">
              <span class="text-[0.65rem] uppercase tracking-[0.35em] text-slate-400">
                Logged in
              </span>
              <span>{@user.email_prefix}</span>
            </div>
            <.link
              navigate={~p"/users/log-out"}
              method="delete"
              class="hidden rounded-full border border-slate-200 px-3 py-1 text-xs font-semibold text-slate-600 transition hover:border-slate-300 hover:text-slate-900 lg:inline-flex"
            >
              Sign out
            </.link>
          </div>
        </div>
      </div>
    </header>
    """
  end

  @doc """
  Page header with breadcrumbs, title, subtitle, and optional actions/meta slots.
  """
  attr :id, :string, default: "page-header"
  attr :eyebrow, :string, default: nil
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :breadcrumbs, :list, default: []
  attr :meta, :list, default: []
  attr :class, :string, default: nil

  slot :actions, doc: "Action buttons rendered to the right of the header."

  def page_header(assigns) do
    breadcrumbs = Enum.map(assigns.breadcrumbs, &normalize_breadcrumb!/1)

    assigns =
      assigns
      |> assign(:breadcrumbs, breadcrumbs)
      |> assign(:has_actions?, assigns.actions != [])
      |> assign(:has_meta_badges?, assigns.meta not in [nil, []])

    ~H"""
    <header
      id={@id}
      class={[
        "page-header relative overflow-hidden rounded-[32px] border border-white/15 bg-gradient-to-br from-slate-900 via-slate-900/95 to-slate-800 px-6 py-8 text-white shadow-[0_40px_90px_-40px_rgba(15,23,42,0.75)] sm:px-8 lg:px-12",
        @class
      ]}
      data-role="page-header"
    >
      <div class="absolute inset-0 -z-[1] opacity-45">
        <div class="absolute -left-10 top-4 h-36 w-36 rounded-full bg-emerald-400/50 blur-[120px]" />
        <div class="absolute bottom-0 right-0 h-48 w-48 rounded-full bg-sky-400/40 blur-[140px]" />
      </div>

      <nav
        :if={@breadcrumbs != []}
        aria-label="Breadcrumb"
        class="mb-5 flex flex-wrap items-center gap-2 text-[0.7rem] font-semibold uppercase tracking-[0.4em] text-white/60"
      >
        <.link
          :for={crumb <- @breadcrumbs}
          navigate={crumb.href}
          class={[
            "inline-flex items-center gap-2 transition hover:text-white",
            crumb.current? && "text-white"
          ]}
          data-role="breadcrumb"
          data-current={to_string(crumb.current?)}
        >
          <span>{crumb.label}</span>
          <.icon
            :if={!crumb.current?}
            name="hero-chevron-right"
            class="h-3 w-3 text-white/40"
          />
        </.link>
      </nav>

      <div class="flex flex-wrap items-start justify-between gap-6">
        <div class="space-y-4">
          <p :if={@eyebrow} class="text-[0.65rem] uppercase tracking-[0.65em] text-white/60">
            {@eyebrow}
          </p>
          <h1 class="text-4xl font-semibold tracking-tight sm:text-5xl">
            {@title}
          </h1>
          <p :if={@subtitle} class="max-w-2xl text-base text-white/75 sm:text-lg">
            {@subtitle}
          </p>
        </div>

        <div :if={@has_actions?} class="inline-flex flex-wrap items-center gap-3">
          {render_slot(@actions)}
        </div>
      </div>

      <div
        :if={@meta != [] or @meta != nil}
        class="mt-8 flex flex-wrap items-center gap-3 text-xs font-medium uppercase tracking-[0.35em] text-white/60"
      >
        <span
          :for={entry <- @meta}
          class="inline-flex items-center gap-2 rounded-full bg-white/10 px-3 py-1.5 text-[0.65rem] font-semibold text-white/80 shadow-inner"
        >
          <.icon :if={entry[:icon]} name={entry.icon} class="h-3.5 w-3.5 text-emerald-300" />
          {entry[:label]}
        </span>
      </div>
    </header>
    """
  end

  @doc """
  Shared empty state component with iconography and optional actions.
  """
  attr :id, :string, required: true
  attr :icon, :string, default: "hero-sparkles"
  attr :title, :string, required: true
  attr :message, :string, required: true
  attr :context, :string, default: nil
  attr :class, :string, default: nil

  slot :actions, doc: "Optional action buttons below the message."

  def empty_state(assigns) do
    assigns =
      assigns
      |> assign_new(:context, fn -> nil end)
      |> assign(:has_actions?, assigns.actions != [])

    ~H"""
    <div
      id={@id}
      data-role="empty-state"
      data-context={@context}
      class={[
        "chrome-empty-state flex flex-col items-center justify-center gap-4 rounded-3xl border border-dashed border-slate-200/70 bg-white/80 px-6 py-12 text-center text-slate-600 shadow-[inset_0_1px_0_rgba(255,255,255,0.45)]",
        @class
      ]}
    >
      <div class="inline-flex h-12 w-12 items-center justify-center rounded-full bg-slate-900 text-white shadow-lg shadow-slate-950/30">
        <.icon name={@icon} class="h-5 w-5" />
      </div>
      <div class="space-y-1">
        <p data-empty-title class="text-base font-semibold text-slate-900">
          {@title}
        </p>
        <p class="text-sm text-slate-600">
          {@message}
        </p>
      </div>
      <div :if={@has_actions?} class="mt-2 inline-flex flex-wrap items-center justify-center gap-3">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  @doc """
  Workspace skeleton used while snippet detail chrome loads.
  """
  attr :id, :string, default: "workspace-skeleton"

  def workspace_skeleton(assigns) do
    ~H"""
    <div
      id={@id}
      class="chrome-skeleton grid gap-6 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]"
    >
      <div class="space-y-4 rounded-3xl border border-slate-200/70 bg-white/85 p-6 shadow-sm shadow-slate-200/40">
        <div class="chrome-skeleton-bar h-6 w-1/3" />
        <div class="chrome-skeleton-bar h-12 w-4/5" />
        <div class="chrome-skeleton-bar h-48 w-full" />
      </div>

      <div class="space-y-4">
        <div class="chrome-skeleton-card h-32" />
        <div class="chrome-skeleton-card h-40" />
        <div class="chrome-skeleton-card h-48" />
      </div>
    </div>
    """
  end

  defp nav_items(active_item, has_user?) do
    [
      %{id: :discover, label: "Discover", icon: "hero-sparkles", href: ~p"/snippets"},
      %{
        id: :workspace,
        label: "Workspace",
        icon: "hero-command-line",
        href: ~p"/snippets/my",
        requires_auth?: true
      },
      %{
        id: :account,
        label: "Account",
        icon: "hero-user-circle",
        href: ~p"/users/settings",
        requires_auth?: true
      }
    ]
    |> Enum.map(fn item ->
      item
      |> Map.put(:active?, item.id == active_item)
      |> Map.put(:disabled?, Map.get(item, :requires_auth?, false) && !has_user?)
    end)
  end

  defp nav_icon_class(true), do: "h-4 w-4 transition-colors text-white"
  defp nav_icon_class(_), do: "h-4 w-4 transition-colors"

  defp nav_user(nil), do: nil

  defp nav_user(%{user: nil}), do: nil

  defp nav_user(%{user: user}) do
    %{
      email: user.email,
      email_prefix: email_prefix(user.email),
      initials: initials_from(user.email || "")
    }
  end

  defp nav_user(_), do: nil

  defp email_prefix(nil), do: "profile"

  defp email_prefix(email) when is_binary(email) do
    email
    |> String.split("@")
    |> List.first()
    |> case do
      nil -> "profile"
      prefix -> prefix
    end
  end

  defp initials_from(nil), do: "RR"

  defp initials_from(email) do
    email
    |> String.split("@")
    |> List.first()
    |> case do
      nil ->
        "RR"

      prefix ->
        prefix
        |> String.slice(0, 2)
        |> String.upcase()
    end
  end

  defp normalize_breadcrumb!(%{label: label} = breadcrumb) when is_binary(label) do
    breadcrumb
    |> Map.put_new(:href, ~p"/")
    |> Map.put_new(:current?, false)
    |> Map.update!(:current?, &(!!&1))
  end

  defp normalize_breadcrumb!(_invalid) do
    raise ArgumentError, "Breadcrumb entries must include at least :label"
  end
end
