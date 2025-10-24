defmodule ReviewRoomWeb.SnippetLive.IndexTest do
  use ReviewRoomWeb.ConnCase, async: true
  use ReviewRoomWeb.DesignSystemCase

  import Phoenix.LiveViewTest
  import ReviewRoom.SnippetsFixtures
  import Ecto.Changeset
  alias ReviewRoom.Repo
  alias ReviewRoom.AccountsFixtures

  describe "public gallery" do
    test "mount loads public snippets as stream", %{conn: conn} do
      public = snippet_fixture(%{visibility: :public, title: "Visible"})
      private = snippet_fixture(%{visibility: :private, title: "Hidden"})

      {:ok, view, _html} = live(conn, ~p"/snippets")

      assert has_element?(view, "#snippets-#{public.id}")
      refute has_element?(view, "#snippets-#{private.id}")
    end

    test "filter event resets stream with filtered results", %{conn: conn} do
      elixir = snippet_fixture(%{visibility: :public, language: "elixir", title: "Elixir"})
      python = snippet_fixture(%{visibility: :public, language: "python", title: "Python"})

      {:ok, view, _html} = live(conn, ~p"/snippets")

      view
      |> element("#language-filter-form")
      |> render_change(%{"filters" => %{"language" => "python"}})

      assert has_element?(view, "#snippets-#{python.id}")
      refute has_element?(view, "#snippets-#{elixir.id}")
    end

    test "search event resets stream with search results", %{conn: conn} do
      phoenix = snippet_fixture(%{visibility: :public, title: "Phoenix Patterns"})
      other = snippet_fixture(%{visibility: :public, title: "LiveView Tricks"})

      {:ok, view, _html} = live(conn, ~p"/snippets")

      view
      |> element("#snippet-search-form")
      |> render_submit(%{"search" => %{"query" => "phoenix"}})

      assert has_element?(view, "#snippets-#{phoenix.id}")
      refute has_element?(view, "#snippets-#{other.id}")
    end

    test "load_more appends to stream", %{conn: conn} do
      page_size = ReviewRoomWeb.SnippetLive.Index.page_size()

      now = DateTime.utc_now()

      snippets =
        for offset <- 0..page_size do
          snippet_fixture(%{visibility: :public, title: "Snippet #{offset}"})
          |> set_inserted_at(DateTime.add(now, -offset * 60, :second))
        end

      newest = hd(snippets)
      oldest = List.last(snippets)

      {:ok, view, _html} = live(conn, ~p"/snippets")

      assert has_element?(view, "#snippets-#{newest.id}")
      refute has_element?(view, "#snippets-#{oldest.id}")
      assert has_element?(view, "#load-more")

      view
      |> element("#load-more")
      |> render_click()

      assert has_element?(view, "#snippets-#{oldest.id}")
    end

    test "private snippets are never shown", %{conn: conn} do
      public = snippet_fixture(%{visibility: :public, title: "Public Phoenix"})
      private = snippet_fixture(%{visibility: :private, title: "Private Phoenix"})

      {:ok, view, _html} = live(conn, ~p"/snippets")

      assert has_element?(view, "#snippets-#{public.id}")
      refute has_element?(view, "#snippets-#{private.id}")

      view
      |> element("#snippet-search-form")
      |> render_submit(%{"search" => %{"query" => "phoenix"}})

      refute has_element?(view, "#snippets-#{private.id}")
    end
  end

  defp set_inserted_at(snippet, datetime) do
    snippet
    |> change(inserted_at: DateTime.truncate(datetime, :second))
    |> Repo.update!()
  end

  describe "gallery design system" do
    test "renders hero layout with world-class toggles", %{conn: conn} do
      snippet_fixture(%{visibility: :public, title: "Prime"})

      {:ok, view, _html} = live(conn, ~p"/snippets")

      assert has_element?(view, "#gallery-hero h1", "World-Class Snippet Library")

      assert has_element?(
               view,
               "#gallery-layout-toggle button[data-layout=\"grid\"][aria-pressed=\"true\"]"
             )

      assert has_element?(
               view,
               "#gallery-layout-toggle button[data-layout=\"list\"][aria-pressed=\"false\"]"
             )
    end

    test "filter panel overlay opts into FilterPanelToggle hook", %{conn: conn} do
      snippet_fixture(%{visibility: :public, title: "Filterable"})

      {:ok, view, _html} = live(conn, ~p"/snippets")

      [{"section", attrs, _children}] = render_lazy_tree(view, "#gallery-filter-panel")

      assert {"phx-hook", "FilterPanelToggle"} in attrs
      assert {"phx-update", "ignore"} in attrs
      assert {"data-trigger", "#gallery-filters-trigger"} in attrs
    end

    test "cards display owner, language badge, and micro-copy", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      snippet_fixture_with_user(user, %{visibility: :public, title: "Owner Snippet"})

      {:ok, view, _html} = live(conn, ~p"/snippets")

      assert has_element?(
               view,
               "[data-role='gallery-card'] [data-role='gallery-card-owner']",
               user.email
             )

      assert has_element?(
               view,
               "[data-role='gallery-card'] [data-role='gallery-language']",
               "Elixir"
             )

      assert has_element?(view, "#gallery-stream[phx-update='stream']")
    end
  end
end
