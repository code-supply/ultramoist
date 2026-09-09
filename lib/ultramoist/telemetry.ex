defmodule Ultramoist.Telemetry do
  @moduledoc """
  The canonical list of `:telemetry` events ultramoist emits.

  Attach to all of them without hand-typing each event name:

      :telemetry.attach_many(MyHandler, Ultramoist.Telemetry.events(), &handler/4, nil)
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
    [:ultramoist, :web_socket, :subscribe]
  ]

  def events, do: @events
end
