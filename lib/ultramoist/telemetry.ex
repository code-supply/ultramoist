defmodule Ultramoist.Telemetry do
  @moduledoc """
  The canonical list of `:telemetry` events ultramoist emits.

  Attach to all of them without hand-typing each event name:

      :telemetry.attach_many(MyHandler, Ultramoist.Telemetry.events(), &handler/4, nil)

  ## Events

  ### HTTP (`Ultramoist.Http`)

  Each of the three request functions (`info_request/2`, `stats_request/2`,
  `exchange_request/2`) emits a `:telemetry.span/3` under
  `[:ultramoist, :http, <function>]` (`:start`/`:stop`/`:exception`), with
  `:stop` metadata:

    * `:base_url` - the host the request was sent to
    * `:type` - the request's type/action (e.g. `"meta"` for an info
      request, `"vaults"` for a stats request, `"cancel"` for an exchange
      request's action type - never the full signed payload)

  `:exception` metadata additionally carries `:kind`, `:reason`, `:stacktrace`
  (the standard `:telemetry.span/3` exception shape).

  ### WebSocket (`Ultramoist.WebSocket`)

    * `[:ultramoist, :web_socket, :connect_attempt]` (span) - wraps the
      transport's `open/2` call. `:stop` metadata: `:url`, `:outcome`
      (`:ok` or `:error`), and on `:error` also `:reason`.
    * `[:ultramoist, :web_socket, :connected]` - the transport confirmed the
      connection is live. Metadata: `:url`.
    * `[:ultramoist, :web_socket, :disconnected]` - the transport reported a
      drop. Metadata: `:url`.
    * `[:ultramoist, :web_socket, :reconnect_scheduled]` - fired whenever a
      reconnect gets scheduled (after either a disconnect or a failed
      connect attempt). Metadata: `:url`, `:delay_ms`, `:attempt`.
    * `[:ultramoist, :web_socket, :subscribe]` - one per `subscribe/4` call.
      Metadata: `:url`, `:key`, `:subscription`, `:outcome` (`:subscribed` if
      a subscribe envelope was actually sent, `:noop` if the key or content
      was already active).
    * `[:ultramoist, :web_socket, :unsubscribe]` - one per `unsubscribe/2`
      call. Metadata: `:url`, `:key`, `:outcome` (`:unsubscribed` if an
      unsubscribe envelope was actually sent, `:noop` otherwise).
    * `[:ultramoist, :web_socket, :frame_received]` - one per inbound frame,
      summary-level only (no payload). Metadata: `:url`, `:channel` (from the
      frame's own `"channel"` field), `:match_count` (how many live
      subscriptions the frame matched).
  """

  @events [
    [:ultramoist, :http, :info_request, :start],
    [:ultramoist, :http, :info_request, :stop],
    [:ultramoist, :http, :info_request, :exception],
    [:ultramoist, :http, :stats_request, :start],
    [:ultramoist, :http, :stats_request, :stop],
    [:ultramoist, :http, :stats_request, :exception],
    [:ultramoist, :http, :exchange_request, :start],
    [:ultramoist, :http, :exchange_request, :stop],
    [:ultramoist, :http, :exchange_request, :exception],
    [:ultramoist, :web_socket, :connect_attempt, :start],
    [:ultramoist, :web_socket, :connect_attempt, :stop],
    [:ultramoist, :web_socket, :connect_attempt, :exception],
    [:ultramoist, :web_socket, :connected],
    [:ultramoist, :web_socket, :disconnected],
    [:ultramoist, :web_socket, :reconnect_scheduled],
    [:ultramoist, :web_socket, :subscribe],
    [:ultramoist, :web_socket, :unsubscribe],
    [:ultramoist, :web_socket, :frame_received]
  ]

  def events, do: @events
end
