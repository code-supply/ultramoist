defmodule Ultramoist.TelemetryTest do
  use ExUnit.Case, async: true

  alias Ultramoist.Telemetry

  # @spec TELEM-API-002
  # @spec TELEM-API-004
  test "includes every event an HTTP request can emit, so other handlers can reuse it" do
    events = Telemetry.events()

    assert [:ultramoist, :http, :info_request, :start] in events
    assert [:ultramoist, :http, :info_request, :stop] in events
    assert [:ultramoist, :http, :info_request, :exception] in events
    assert [:ultramoist, :http, :stats_request, :start] in events
    assert [:ultramoist, :http, :stats_request, :stop] in events
    assert [:ultramoist, :http, :stats_request, :exception] in events
  end
end
