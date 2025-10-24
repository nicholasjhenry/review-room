defmodule ReviewRoomWeb.DesignSystemCase do
  @moduledoc """
  Shared helpers for design system LiveView assertions.

  Provides a thin wrapper around `LazyHTML` so tests can snapshot rendered
  fragments with stable attribute ordering and trimmed whitespace. Use these
  helpers when authoring the Spec 003 redesign tests to keep assertions
  expressive and resilient.
  """

  use ExUnit.CaseTemplate

  alias LazyHTML
  alias Phoenix.HTML
  alias Phoenix.LiveViewTest

  @default_tree_opts [sort_attributes: true, skip_whitespace_nodes: true]

  using do
    quote do
      import ReviewRoomWeb.DesignSystemCase,
        only: [
          lazy_fragment: 1,
          lazy_select: 2,
          lazy_tree: 1,
          lazy_tree: 2,
          render_lazy_tree: 1,
          render_lazy_tree: 2,
          render_lazy_tree: 3
        ]
    end
  end

  @doc """
  Converts template output into a `LazyHTML` fragment.
  """
  @spec lazy_fragment(
          LazyHTML.t()
          | binary()
          | Phoenix.HTML.safe()
          | Phoenix.LiveViewTest.View.t()
        ) ::
          LazyHTML.t()
  def lazy_fragment(%LazyHTML{} = doc), do: doc

  def lazy_fragment({:safe, _} = safe_html) do
    safe_html
    |> HTML.safe_to_string()
    |> LazyHTML.from_fragment()
  end

  def lazy_fragment(%LiveViewTest.View{} = view) do
    view
    |> LiveViewTest.render()
    |> lazy_fragment()
  end

  def lazy_fragment(html) when is_binary(html), do: LazyHTML.from_fragment(html)

  @doc """
  Filters a fragment using a CSS selector.
  """
  @spec lazy_select(
          LazyHTML.t() | binary() | Phoenix.HTML.safe() | Phoenix.LiveViewTest.View.t(),
          String.t()
        ) ::
          LazyHTML.t()
  def lazy_select(fragment, selector) when is_binary(selector) do
    fragment
    |> lazy_fragment()
    |> LazyHTML.query(selector)
  end

  @doc """
  Normalises HTML into a deterministic tree for snapshot comparisons.
  """
  @spec lazy_tree(LazyHTML.t() | binary() | Phoenix.HTML.safe() | Phoenix.LiveViewTest.View.t()) ::
          LazyHTML.Tree.t()
  def lazy_tree(fragment) do
    fragment
    |> lazy_fragment()
    |> LazyHTML.to_tree(@default_tree_opts)
  end

  @doc """
  Normalises selected HTML into a deterministic tree for snapshot comparisons.
  """
  @spec lazy_tree(
          LazyHTML.t() | binary() | Phoenix.HTML.safe() | Phoenix.LiveViewTest.View.t(),
          String.t()
        ) :: LazyHTML.Tree.t()
  def lazy_tree(fragment, selector) when is_binary(selector) do
    fragment
    |> lazy_select(selector)
    |> LazyHTML.to_tree(@default_tree_opts)
  end

  @doc """
  Renders a LiveView and returns a stable LazyHTML tree.
  """
  @spec render_lazy_tree(Phoenix.LiveViewTest.View.t()) :: LazyHTML.Tree.t()
  def render_lazy_tree(%LiveViewTest.View{} = view) do
    view
    |> LiveViewTest.render()
    |> lazy_tree()
  end

  @doc """
  Renders a LiveView, filters by `selector`, and returns a stable LazyHTML tree.
  """
  @spec render_lazy_tree(Phoenix.LiveViewTest.View.t(), String.t()) :: LazyHTML.Tree.t()
  def render_lazy_tree(%LiveViewTest.View{} = view, selector) when is_binary(selector) do
    view
    |> LiveViewTest.render()
    |> lazy_tree(selector)
  end

  @doc """
  Same as `render_lazy_tree/2`, but accepts additional `LazyHTML.to_tree/2` opts.
  """
  @spec render_lazy_tree(Phoenix.LiveViewTest.View.t(), String.t(), keyword()) ::
          LazyHTML.Tree.t()
  def render_lazy_tree(%LiveViewTest.View{} = view, selector, opts)
      when is_binary(selector) and is_list(opts) do
    view
    |> LiveViewTest.render()
    |> lazy_select(selector)
    |> LazyHTML.to_tree(Keyword.merge(@default_tree_opts, opts))
  end
end
