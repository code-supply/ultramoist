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
    [:ultramoist, :http, :exchange_request, :exception]
  ]

  def events, do: @events
end
