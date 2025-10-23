defmodule ReviewRoom.Snippets.PresenceTracker do
  @moduledoc """
  Phoenix Tracker for managing user presence in snippet viewing sessions.

  Tracks which users are viewing each snippet and broadcasts presence updates
  via PubSub to all connected viewers.
  """

  use Phoenix.Tracker

  @doc """
  Starts the presence tracker.
  """
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(opts) do
    opts = Keyword.merge([name: __MODULE__], opts)
    Phoenix.Tracker.start_link(__MODULE__, opts, opts)
  end

  @doc """
  Initializes the tracker with PubSub configuration.
  """
  @impl true
  def init(opts) do
    server = Keyword.fetch!(opts, :pubsub_server)
    {:ok, %{pubsub_server: server, node_name: Phoenix.PubSub.node_name(server)}}
  end

  @doc """
  Handles presence diff and broadcasts changes via PubSub.
  """
  @impl true
  def handle_diff(diff, state) do
    for {topic, {joins, leaves}} <- diff do
      Phoenix.PubSub.broadcast(
        state.pubsub_server,
        topic,
        {:presence_diff, %{joins: joins, leaves: leaves}}
      )
    end

    {:ok, state}
  end

  @doc """
  Tracks a user joining a snippet viewing session.

  ## Examples

      iex> track_user("snippet123", "user_abc", %{cursor: nil, display_name: "Alice"})
      {:ok, ref}

  """
  @spec track_user(String.t(), String.t(), map()) :: {:ok, binary()} | {:error, term()}
  def track_user(snippet_id, user_id, user_meta) do
    Phoenix.Tracker.track(__MODULE__, self(), topic(snippet_id), user_id, user_meta)
  end

  @doc """
  Updates cursor position for a user in a snippet session.

  Merges the new cursor metadata with existing metadata to preserve display_name and color.

  ## Examples

      iex> update_cursor("snippet123", "user_abc", %{cursor: %{line: 10, column: 5}})
      {:ok, ref}

  """
  @spec update_cursor(String.t(), String.t(), map()) :: {:ok, binary()} | {:error, term()}
  def update_cursor(snippet_id, user_id, cursor_meta) do
    Phoenix.Tracker.update(__MODULE__, self(), topic(snippet_id), user_id, fn existing_meta ->
      Map.merge(existing_meta, cursor_meta)
    end)
  end

  @doc """
  Lists all users currently viewing a snippet.

  Returns a map where keys are user IDs and values contain metadata lists.

  ## Examples

      iex> list_presences("snippet123")
      %{"user_abc" => %{metas: [%{cursor: nil, display_name: "Alice"}]}}

  """
  @spec list_presences(String.t()) :: map()
  def list_presences(snippet_id) do
    __MODULE__
    |> Phoenix.Tracker.list(topic(snippet_id))
    |> Enum.into(%{}, fn {user_id, meta} ->
      {user_id, %{metas: [meta]}}
    end)
  end

  defp topic(snippet_id), do: "snippet:#{snippet_id}"
end
