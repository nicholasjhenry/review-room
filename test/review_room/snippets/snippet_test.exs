defmodule ReviewRoom.Snippets.SnippetTest do
  use ReviewRoom.DataCase, async: true

  alias ReviewRoom.Snippets.Snippet

  describe "changeset/2" do
    test "requires title and code" do
      changeset = Snippet.changeset(%Snippet{}, %{})

      assert %{title: ["can't be blank"], code: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates title length (1-200 chars)" do
      # Title too short (empty string) - validate_required catches this first
      changeset = Snippet.changeset(%Snippet{}, %{title: "", code: "test"})
      assert %{title: ["can't be blank"]} = errors_on(changeset)

      # Title too long (201 chars)
      long_title = String.duplicate("a", 201)
      changeset = Snippet.changeset(%Snippet{}, %{title: long_title, code: "test"})
      assert %{title: ["should be at most 200 character(s)"]} = errors_on(changeset)

      # Valid title lengths
      changeset = Snippet.changeset(%Snippet{}, %{title: "a", code: "test"})
      refute Map.has_key?(errors_on(changeset), :title)

      changeset =
        Snippet.changeset(%Snippet{}, %{title: String.duplicate("a", 200), code: "test"})

      refute Map.has_key?(errors_on(changeset), :title)
    end

    test "validates code size (max 500KB)" do
      # Code too large (> 512,000 bytes)
      large_code = String.duplicate("a", 512_001)
      changeset = Snippet.changeset(%Snippet{}, %{title: "Test", code: large_code})
      assert %{code: ["should be at most 512000 character(s)"]} = errors_on(changeset)

      # Valid code size
      valid_code = String.duplicate("a", 512_000)
      changeset = Snippet.changeset(%Snippet{}, %{title: "Test", code: valid_code})
      refute Map.has_key?(errors_on(changeset), :code)
    end

    test "accepts optional description (max 2000 chars)" do
      # No description is valid
      changeset = Snippet.changeset(%Snippet{}, %{title: "Test", code: "code"})
      assert changeset.valid?

      # Description too long (> 2000 chars)
      long_desc = String.duplicate("a", 2001)

      changeset =
        Snippet.changeset(%Snippet{}, %{title: "Test", code: "code", description: long_desc})

      assert %{description: ["should be at most 2000 character(s)"]} = errors_on(changeset)

      # Valid description
      valid_desc = String.duplicate("a", 2000)

      changeset =
        Snippet.changeset(%Snippet{}, %{title: "Test", code: "code", description: valid_desc})

      refute Map.has_key?(errors_on(changeset), :description)
    end

    test "defaults visibility to :private" do
      changeset = Snippet.changeset(%Snippet{}, %{title: "Test", code: "code"})
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :visibility) == :private
    end
  end
end
