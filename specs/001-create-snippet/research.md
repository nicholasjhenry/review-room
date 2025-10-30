# Research Findings – Creating a Snippet

## Buffer Mechanism for Deferred Persistence

Decision: Stage snippet submissions inside a supervised `ReviewRoom.Snippets.Buffer` GenServer that holds an in-memory queue per snippet scope.
Rationale: A GenServer maintains ordered, process-safe state without extra dependencies, integrates cleanly with supervision for crash recovery, and provides natural hook points for flush instrumentation.
Alternatives considered: ETS table (adds complexity for writes and ownership without clear throughput benefit); Direct-to-Repo writes (violates defer requirement and increases response latency); Mnesia/disk-backed queues (overkill for current volume and adds operational load).

## Flush Trigger Strategy

Decision: Flush the buffer when either (a) the queue reaches 10 pending snippets or (b) a 5-second inactivity timer fires, with explicit flush on application shutdown and manual admin command.
Rationale: Combining size and time thresholds keeps latency bounded, minimizes data at risk, and aligns with workloads (<100 snippets/hour). Explicit shutdown flush ensures durability during deploys, while manual flush aids ops.
Alternatives considered: Time-based only (risk of backlog during bursts), size-based only (long delays during low activity), immediate writes (violates batching requirement), or scheduled cron flush (coarser control, delayed feedback).

## Retry and Observability Strategy

Decision: On flush failure, retain queued entries, exponential backoff retries capped at 3 attempts, emit structured logs with correlation IDs, and expose Telemetry events for monitoring.
Rationale: Ensures durability without duplicate writes, follows Fail Fast principle, and keeps operators informed through logs/metrics.
Alternatives considered: Dropping failed items (data loss), infinite retries (risk of runaway loops), or silent failures (violates constitution).
