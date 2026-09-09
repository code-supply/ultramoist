defmodule Ultramoist.Telemetry do
  @moduledoc """
  The canonical list of `:telemetry` events ultramoist emits.

  Attach to all of them without hand-typing each event name:

      :telemetry.attach_many(MyHandler, Ultramoist.Telemetry.events(), &handler/4, nil)
  """

  @events [
    [:ultramoist, :http, :info_request, :start],
    [:ultramoist, :http, :info_request, :stop],
    [:ultramoist, :http, :info_request, :exception]
  ]

  def events, do: @events
end
