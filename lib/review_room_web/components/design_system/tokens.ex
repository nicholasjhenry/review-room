defmodule ReviewRoomWeb.Components.DesignSystem.Tokens do
  @moduledoc """
  Canonical design tokens for the Spec 003 redesign.

  These values bridge the authored CSS in `assets/css/design-system.css`
  with LiveView components and DaisyUI themes. Tokens are grouped by the
  categories captured in the Phase 1 research: color, typography, spacing,
  radii, shadows, and motion.

  To keep Tailwind v4, DaisyUI, and LiveView templates in sync:

    * Use these helpers when deriving class lists in Elixir (for example,
      to map semantic colors to component variants).
    * Keep the CSS custom properties in `design-system.css` aligned with
      the values exposed here so reduced-motion and dark-mode overrides
      stay predictable.
  """

  @type color_token ::
          :primary
          | :primary_soft
          | :accent
          | :surface
          | :surface_high
          | :backdrop
          | :info
          | :success
          | :warning
          | :danger
          | :text_primary
          | :text_secondary

  @type typography_token ::
          :display
          | :headline
          | :title
          | :body
          | :label
          | :code

  @type motion_token :: :fast | :standard | :emphasis

  @type token_map :: %{optional(atom()) => any()}

  @colors %{
    primary: "oklch(64% 0.20 278)",
    primary_soft: "oklch(88% 0.04 278)",
    accent: "oklch(71% 0.16 38)",
    surface: "oklch(97% 0.01 255)",
    surface_high: "oklch(91% 0.02 255)",
    backdrop: "oklch(16% 0.01 258)",
    info: "oklch(68% 0.15 231)",
    success: "oklch(69% 0.12 166)",
    warning: "oklch(76% 0.14 75)",
    danger: "oklch(57% 0.22 25)",
    text_primary: "oklch(18% 0.01 262)",
    text_secondary: "oklch(42% 0.02 262)"
  }

  @typography %{
    display: %{
      family: "var(--rr-font-display, 'Satoshi', 'Inter', 'Helvetica Neue', sans-serif)",
      size: "clamp(2.75rem, 6vw, 3.75rem)",
      line_height: "1.08",
      weight: 700,
      tracking: "-0.04em"
    },
    headline: %{
      family: "var(--rr-font-sans, 'Inter', 'Helvetica Neue', sans-serif)",
      size: "clamp(1.875rem, 4vw, 2.5rem)",
      line_height: "1.15",
      weight: 650,
      tracking: "-0.02em"
    },
    title: %{
      family: "var(--rr-font-sans, 'Inter', 'Helvetica Neue', sans-serif)",
      size: "1.5rem",
      line_height: "1.3",
      weight: 600,
      tracking: "-0.01em"
    },
    body: %{
      family: "var(--rr-font-sans, 'Inter', 'Helvetica Neue', sans-serif)",
      size: "1rem",
      line_height: "1.6",
      weight: 420,
      tracking: "-0.01em"
    },
    label: %{
      family: "var(--rr-font-sans, 'Inter', 'Helvetica Neue', sans-serif)",
      size: "0.875rem",
      line_height: "1.25",
      weight: 560,
      tracking: "0.04em"
    },
    code: %{
      family: "var(--rr-font-mono, 'Fira Code', 'SFMono-Regular', 'Menlo', monospace)",
      size: "0.9375rem",
      line_height: "1.55",
      weight: 540,
      tracking: "0em"
    }
  }

  @spacing Enum.into(0..12, %{}, fn step ->
             # 4px base unit, expressed in rem for Tailwind alignment.
             value =
               case step do
                 0 -> "0"
                 _ -> "#{Float.round(step * 0.25, 3)}rem"
               end

             {step, value}
           end)

  @radii %{
    xs: "0.25rem",
    sm: "0.375rem",
    md: "0.625rem",
    lg: "0.875rem",
    xl: "1.25rem",
    pill: "999px"
  }

  @shadows %{
    subtle: "0 1px 2px rgba(15, 23, 42, 0.04)",
    soft: "0 12px 40px -24px rgba(15, 23, 42, 0.45)",
    focus: "0 0 0 3px color-mix(in oklch, var(--rr-color-primary) 28%, transparent)",
    inset: "inset 0 1px 0 rgba(255, 255, 255, 0.18), inset 0 -1px 0 rgba(15, 23, 42, 0.08)"
  }

  @motion %{
    fast: %{duration: 150, easing: "cubic-bezier(0.4, 1, 0.6, 1)"},
    standard: %{duration: 200, easing: "cubic-bezier(0.34, 1.56, 0.64, 1)"},
    emphasis: %{duration: 260, easing: "cubic-bezier(0.24, 1, 0.32, 1)"}
  }

  @doc "Full color palette."
  @spec colors() :: %{color_token() => String.t()}
  def colors, do: @colors

  @doc "Typographic scale with font families and rhythm metadata."
  @spec typography() :: %{typography_token() => map()}
  def typography, do: @typography

  @doc "Spacing ramp expressed as 4px increments (in rem)."
  @spec spacing_scale() :: %{non_neg_integer() => String.t()}
  def spacing_scale, do: @spacing

  @doc "Border radius tokens for cards, inputs, and buttons."
  @spec radii() :: %{atom() => String.t()}
  def radii, do: @radii

  @doc "Shadow elevations for surfaces and focus rings."
  @spec shadows() :: %{atom() => String.t()}
  def shadows, do: @shadows

  @doc "Standard motion timings and easing curves."
  @spec motion() :: %{motion_token() => %{duration: pos_integer(), easing: String.t()}}
  def motion, do: @motion

  @doc """
  Returns all token categories in a single map.

  Useful for serialising into assign-friendly formats or exporting to JSON
  for design QA tools.
  """
  @spec to_map() :: token_map()
  def to_map do
    %{
      colors: colors(),
      typography: typography(),
      spacing: spacing_scale(),
      radii: radii(),
      shadows: shadows(),
      motion: motion()
    }
  end

  @doc """
  Converts the registered colors into DaisyUI compatible theme tokens.

  The keys match the DaisyUI contract so the resulting map can be merged into
  runtime theme configuration without duplicating values.
  """
  @spec daisyui_theme() :: %{String.t() => String.t()}
  def daisyui_theme do
    %{
      "primary" => @colors.primary,
      "primary-content" => "oklch(97% 0.02 275)",
      "secondary" => @colors.accent,
      "secondary-content" => "oklch(99% 0.01 52)",
      "accent" => @colors.info,
      "accent-content" => "oklch(99% 0.008 240)",
      "neutral" => @colors.text_primary,
      "neutral-content" => "oklch(97% 0.01 256)",
      "base-100" => @colors.surface,
      "base-200" => @colors.surface_high,
      "base-300" => "oklch(85% 0.015 255)",
      "base-content" => @colors.text_primary,
      "info" => @colors.info,
      "info-content" => "oklch(97% 0.012 232)",
      "success" => @colors.success,
      "success-content" => "oklch(98% 0.012 170)",
      "warning" => @colors.warning,
      "warning-content" => "oklch(99% 0.02 90)",
      "error" => @colors.danger,
      "error-content" => "oklch(96% 0.015 20)"
    }
  end
end
