# Telemetry Instrumentation

## Vision

Every network-facing operation ultramoist performs today is silent - no logs, no telemetry, nothing. Give consumers (hl_auto, or anyone else who depends on this library) a standard, `:telemetry`-based way to observe what ultramoist is doing - requests, responses, failures, connection state - without reading ultramoist's source or polling internal state.

## Context

ultramoist is a pure-Elixir Hyperliquid client, built to replace a Rust-NIF dependency in its sibling project hl_auto. As a library it correctly has no `Logger` calls of its own - a library shouldn't decide how its host application logs things. But it also has zero `:telemetry` events anywhere, which is the actual standard, consumer-agnostic mechanism for a library to expose observability hooks. Right now there is no way to tell, from outside ultramoist, whether a request is slow, retrying, or has failed; whether the WebSocket is connected, disconnected, or stuck in a reconnect-backoff loop; or whether a subscription is even receiving frames. A consuming application has no attachment point to build a log line, a dashboard, or an alert from.

This gap is a real, felt cost, not a hypothetical one: hl_auto's own operators have had to reconstruct what ultramoist was doing during live incidents by reading `journalctl` output from the *consuming* application and inferring backwards, because ultramoist itself never emitted anything that could be attached to.

## Scope

### In Scope

- Instrument the three functions in `Ultramoist.Http` (`info_request/2`, `stats_request/2`, `exchange_request/2`) with `:telemetry.span/3`. These three are the entire HTTP surface of the library - every other module (`Orders`, `Positions`, `Vaults`, `Universe`, `Candles`, `VaultDetails`) already funnels through them, so instrumenting this one module gives blanket coverage for free, rather than instrumenting each caller individually.
- Instrument `Ultramoist.WebSocket`'s connection lifecycle: connect attempts, successful connects, disconnects, and reconnect scheduling (including the computed backoff delay and the current attempt count).
- Instrument `Ultramoist.WebSocket` subscribe/unsubscribe actions (`handle_call({:subscribe, ...})` / `handle_call({:unsubscribe, ...})`), including the case where a subscribe/unsubscribe is a no-op because an equivalent subscription is already active.
- Instrument inbound WebSocket frame dispatch at a summary level (a frame arrived; how many live subscriptions it matched) - not full payload logging, since mids/book frames arrive continuously and a consumer that wants payloads already has them via its own subscription callback.
- A stable, documented set of event names and metadata keys. For a library, this *is* part of the public API surface - breaking it is a breaking change - so documenting it (module docs, or a dedicated reference doc) is part of this epic, not a follow-up.
- Adding `:telemetry` as an explicit dependency in `mix.exs`. It is already present transitively (via `finch`/`plug` in `mix.lock`), but a library should declare what it actually calls directly rather than relying on an implicit transitive pull.

### Out of Scope

- Any `Logger` call, or any decision about how an event *looks* once logged - that's the consuming application's job. hl_auto already has its own pattern for this (`HlAuto.Telemetry.LogHandler` / `PubsubHandler`) and should attach to whatever events this epic produces, as its own separate follow-up in its own repo.
- Instrumenting pure, local, non-I/O computation: signing (`Signer`, `Eip712`, `Secp256k1`, `Keccak`), msgpack/JSON encoding, and nonce allocation (`NonceAllocator`). These have no network failure mode and no latency worth measuring; telemetry here would be noise, not signal.
- Any specific telemetry backend, exporter, or aggregation (OpenTelemetry, Prometheus, OpenObserve, etc.). `:telemetry` is the neutral attachment point; what anyone does with the events afterward is out of scope.
- Retrofitting hl_auto (or any other consumer) to actually attach to and use these new events. That's real, valuable follow-up work, but it belongs to the consumer's own repo and its own epic.

## Success Criteria

- Every HTTP request ultramoist makes - info, stats, and exchange - emits telemetry (start/stop/exception) with enough metadata (at minimum: which request type/action, the base URL, and on exception the error) that a consumer could build a log line or a dashboard panel without reading ultramoist's source.
- A `Ultramoist.WebSocket` connection's full lifecycle - connecting, connected, disconnected, reconnecting (with delay and attempt count), subscribing, unsubscribing - is independently observable via telemetry, so a consumer can tell "mid backoff-storm" apart from "healthy and connected" without inspecting GenServer state directly.
- Every new event's metadata shape is pinned by a dedicated test (using `:telemetry_test.attach_event_handlers/2`, the same tool hl_auto's own suite already standardizes on), so the contract can't silently drift.
- No existing test's behavior changes as a result of this epic - this is additive instrumentation, not a behavior change, and the full existing suite stays green throughout.
- Event names, and the metadata each one carries, are written down somewhere a consumer can find without reading source - moduledocs at minimum.

## Dependencies

- `:telemetry` needs to move from an implicit transitive dependency to an explicit one in `mix.exs`.
- `Ultramoist.Http` (`lib/ultramoist/http.ex`) and its `Client` behaviour (`lib/ultramoist/http/client.ex`) - the shared chokepoint the HTTP-side stories instrument.
- `Ultramoist.WebSocket` (`lib/ultramoist/web_socket.ex`) - the GenServer the connection/subscription-side stories instrument.
- Nothing here depends on work that doesn't already exist; this epic only adds observation, it doesn't need new capability underneath it.

## Open Questions

- **Span granularity for `exchange_request/2`**: should the metadata include the raw signed `action` payload (useful for debugging exactly what was sent) or just its type/summary (safer - avoids ever telemetry-logging something that resembles a secret, even though the private key itself never touches this payload)? Leans toward action *type* only, but worth a developer decision before implementation.
- **Frame-dispatch volume**: mids/book frames can arrive many times a second. Emitting a `:telemetry.execute` per frame may be too fine-grained for some consumers and effectively free for others. Worth deciding whether this needs a sampling/rate consideration, or whether emitting-and-letting-the-consumer-decide is fine (probably the latter, matching `:telemetry`'s own philosophy, but flagging it since it's the one place volume could matter).
- **Where do event names live**: a `@moduledoc` per instrumented module, or a single reference doc (e.g. `docs/telemetry.md`) listing every event name and its metadata keys in one place? The latter is easier for a consumer to audit against; the former stays closer to the code it describes. No strong reason found yet to prefer one over the other - a developer call, not a technical one.

## Resulting Stories

- _..._
