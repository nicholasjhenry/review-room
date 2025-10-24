defmodule ReviewRoom.Snippets.SnippetTest do
  use ReviewRoom.DataCase, async: true

  alias ReviewRoom.Snippets.Snippet

  import ReviewRoom.AccountsFixtures
  import ReviewRoom.SnippetsFixtures

  describe "create_changeset/3" do
    test "generates nanoid when id is not provided" do
      changeset = Snippet.create_changeset(%Snippet{}, %{code: "def hello, do: :world"})

      assert changeset.valid?
      assert get_field(changeset, :id) != nil
      assert String.length(get_field(changeset, :id)) == 8
    end

    test "requires code field" do
      changeset = Snippet.create_changeset(%Snippet{}, %{title: "No code"})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).code
    end

    test "validates language is in supported list" do
      # Valid language
      changeset =
        Snippet.create_changeset(%Snippet{}, %{code: "print('hello')", language: "python"})

      assert changeset.valid?

      # Invalid language
      changeset = Snippet.create_changeset(%Snippet{}, %{code: "code", language: "invalid_lang"})
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).language
    end

    test "allows nil language for auto-detection" do
      changeset = Snippet.create_changeset(%Snippet{}, %{code: "code", language: nil})
      assert changeset.valid?
    end

    test "validates visibility enum" do
      # Valid visibility
      changeset = Snippet.create_changeset(%Snippet{}, %{code: "code", visibility: :public})
      assert changeset.valid?

      changeset = Snippet.create_changeset(%Snippet{}, %{code: "code", visibility: :private})
      assert changeset.valid?

      # Invalid visibility
      changeset = Snippet.create_changeset(%Snippet{}, %{code: "code", visibility: :invalid})
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).visibility
    end

    test "validates title max length of 200 characters" do
      long_title = String.duplicate("a", 201)
      changeset = Snippet.create_changeset(%Snippet{}, %{code: "code", title: long_title})

      refute changeset.valid?
      assert "should be at most 200 character(s)" in errors_on(changeset).title
    end

    test "sets default visibility to private" do
      changeset = Snippet.create_changeset(%Snippet{}, %{code: "code"})
      assert get_field(changeset, :visibility) == :private
    end

    test "rejects snippets longer than 10,000 lines" do
      code = Enum.map_join(1..10_001, "\n", &"line #{&1}")

      changeset = Snippet.create_changeset(%Snippet{}, %{code: code})

      refute changeset.valid?

      assert "Snippets are limited to 10,000 lines. Consider splitting into multiple snippets." in errors_on(
               changeset
             ).code
    end

    test "associates snippet with user when provided" do
      user = user_fixture()
      changeset = Snippet.create_changeset(%Snippet{}, %{code: "code"}, user)

      assert changeset.valid?
      # Verify user association is set (as a changeset, not the struct itself)
      assert %Ecto.Changeset{} = get_change(changeset, :user)
    end

    test "does not set user_id when user is nil (anonymous)" do
      changeset = Snippet.create_changeset(%Snippet{}, %{code: "code"}, nil)

      assert changeset.valid?
      assert get_field(changeset, :user_id) == nil
    end
  end

  describe "update_changeset/2" do
    test "updates allowed fields" do
      snippet = snippet_fixture()
      attrs = %{code: "updated code", title: "Updated", language: "python"}

      changeset = Snippet.update_changeset(snippet, attrs)

      assert changeset.valid?
      assert get_change(changeset, :code) == "updated code"
      assert get_change(changeset, :title) == "Updated"
      assert get_change(changeset, :language) == "python"
    end

    test "requires code field" do
      snippet = snippet_fixture()
      changeset = Snippet.update_changeset(snippet, %{code: nil})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).code
    end

    test "rejects updates that exceed 10,000 lines" do
      snippet = snippet_fixture()
      code = Enum.map_join(1..10_001, "\n", &"line #{&1}")

      changeset = Snippet.update_changeset(snippet, %{code: code})

      refute changeset.valid?

      assert "Snippets are limited to 10,000 lines. Consider splitting into multiple snippets." in errors_on(
               changeset
             ).code
    end
  end
end
