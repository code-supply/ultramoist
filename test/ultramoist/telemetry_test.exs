defmodule Ultramoist.TelemetryTest do
  use ExUnit.Case, async: true

  alias Ultramoist.Telemetry

  # @spec TELEM-API-002
  test "includes every event an info request can emit" do
    events = Telemetry.events()

    assert [:ultramoist, :http, :info_request, :start] in events
    assert [:ultramoist, :http, :info_request, :stop] in events
    assert [:ultramoist, :http, :info_request, :exception] in events
  end
end
