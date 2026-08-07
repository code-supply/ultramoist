defmodule Ultramoist.WebSocketTest do
  use ExUnit.Case, async: true

  defmodule FakeTransport do
    @behaviour Ultramoist.WebSocket.Transport

    @impl true
    def open(_url, owner) do
      conn = make_ref()
      send(owner, {:ws, conn, :connected})
      {:ok, conn}
    end

    @impl true
    def send_frame(_conn, _frame), do: :ok

    @impl true
    def close(_conn), do: :ok
  end

  defmodule NeverConnectingTransport do
    @behaviour Ultramoist.WebSocket.Transport

    @impl true
    def open(_url, _owner), do: {:ok, make_ref()}

    @impl true
    def send_frame(_conn, _frame), do: :ok

    @impl true
    def close(_conn), do: :ok
  end

  defmodule ReconnectingTransport do
    @behaviour Ultramoist.WebSocket.Transport

    def start(test_pid) do
      Agent.start_link(fn -> %{conn: nil, test_pid: test_pid} end, name: __MODULE__)
    end

    @impl true
    def open(_url, owner) do
      conn = make_ref()
      test_pid = Agent.get_and_update(__MODULE__, fn s -> {s.test_pid, %{s | conn: conn}} end)
      send(test_pid, {:transport_opened, conn})
      send(owner, {:ws, conn, :connected})
      {:ok, conn}
    end

    @impl true
    def send_frame(_conn, _frame), do: :ok

    @impl true
    def close(_conn), do: :ok
  end

  # @spec WS-DATA-001
  test "returns an increasing reconnect delay per attempt, capped at a maximum" do
    assert Ultramoist.WebSocket.backoff_delay(0) == 1_000
    assert Ultramoist.WebSocket.backoff_delay(1) == 2_000
    assert Ultramoist.WebSocket.backoff_delay(5) == 60_000
    assert Ultramoist.WebSocket.backoff_delay(10) == 60_000
  end

  # @spec WS-API-001
  test "reflects connected status once the transport reports connected" do
    {:ok, pid} = Ultramoist.WebSocket.start_link(url: "ws://fake", transport: FakeTransport)

    assert Ultramoist.WebSocket.status(pid) == :connected
  end

  # @spec WS-API-005
  test "reports disconnected status before any connection is established" do
    {:ok, pid} =
      Ultramoist.WebSocket.start_link(url: "ws://fake", transport: NeverConnectingTransport)

    assert Ultramoist.WebSocket.status(pid) == :disconnected
  end

  # @spec WS-API-002
  test "reconnects with a backoff delay after the transport reports a disconnect" do
    {:ok, _agent} = ReconnectingTransport.start(self())

    {:ok, pid} =
      Ultramoist.WebSocket.start_link(
        url: "ws://fake",
        transport: ReconnectingTransport,
        backoff_delay: fn _attempt -> 0 end
      )

    assert_receive {:transport_opened, conn}

    send(pid, {:ws, conn, :disconnected})
    assert Ultramoist.WebSocket.status(pid) == :reconnecting

    assert_receive {:transport_opened, _reconnected_conn}
    assert Ultramoist.WebSocket.status(pid) == :connected
  end
end
