defmodule Ultramoist.WebSocketTest do
  use ExUnit.Case, async: true

  defmodule TestTransport do
    @behaviour Ultramoist.WebSocket.Transport

    def start(test_pid, opts \\ []) do
      auto_connect = Keyword.get(opts, :auto_connect, true)

      Agent.start_link(
        fn -> %{conn: nil, test_pid: test_pid, auto_connect: auto_connect} end,
        name: __MODULE__
      )
    end

    @impl true
    def open(_url, owner) do
      conn = make_ref()

      %{test_pid: test_pid, auto_connect: auto_connect} =
        Agent.get_and_update(__MODULE__, fn s -> {s, %{s | conn: conn}} end)

      if auto_connect, do: send(owner, {:ws, conn, :connected})
      send(test_pid, {:transport_opened, conn})

      {:ok, conn}
    end

    @impl true
    def send_frame(_conn, frame) do
      send(Agent.get(__MODULE__, & &1.test_pid), {:frame_sent, frame})
      :ok
    end

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
    {:ok, _agent} = TestTransport.start(self())
    {:ok, pid} = Ultramoist.WebSocket.start_link(url: "ws://fake", transport: TestTransport)

    assert_receive {:transport_opened, _conn}
    assert Ultramoist.WebSocket.status(pid) == :connected
  end

  # @spec WS-API-005
  test "reports disconnected status before any connection is established" do
    {:ok, _agent} = TestTransport.start(self(), auto_connect: false)

    {:ok, pid} = Ultramoist.WebSocket.start_link(url: "ws://fake", transport: TestTransport)

    assert Ultramoist.WebSocket.status(pid) == :disconnected
  end

  # @spec WS-API-002
  test "reconnects with a backoff delay after the transport reports a disconnect" do
    {:ok, _agent} = TestTransport.start(self())

    {:ok, pid} =
      Ultramoist.WebSocket.start_link(
        url: "ws://fake",
        transport: TestTransport,
        backoff_delay: fn _attempt -> 0 end
      )

    assert_receive {:transport_opened, conn}

    send(pid, {:ws, conn, :disconnected})
    assert Ultramoist.WebSocket.status(pid) == :reconnecting

    assert_receive {:transport_opened, _reconnected_conn}
    assert Ultramoist.WebSocket.status(pid) == :connected
  end

  # @spec WS-API-004
  test "subscribing with an existing key is a no-op" do
    {:ok, _agent} = TestTransport.start(self())
    {:ok, pid} = Ultramoist.WebSocket.start_link(url: "ws://fake", transport: TestTransport)

    assert :ok = Ultramoist.WebSocket.subscribe(pid, "user_fills", "user_fills_frame")
    assert_receive {:frame_sent, "user_fills_frame"}

    assert :ok = Ultramoist.WebSocket.subscribe(pid, "user_fills", "user_fills_frame")
    refute_receive {:frame_sent, _}
  end

  # @spec WS-API-003
  test "resubscribes to all active subscriptions after reconnecting" do
    {:ok, _agent} = TestTransport.start(self())

    {:ok, pid} =
      Ultramoist.WebSocket.start_link(
        url: "ws://fake",
        transport: TestTransport,
        backoff_delay: fn _attempt -> 0 end
      )

    assert_receive {:transport_opened, conn}

    assert :ok = Ultramoist.WebSocket.subscribe(pid, "user_fills", "user_fills_frame")
    assert_receive {:frame_sent, "user_fills_frame"}

    send(pid, {:ws, conn, :disconnected})
    assert_receive {:transport_opened, _reconnected_conn}

    assert_receive {:frame_sent, "user_fills_frame"}
  end
end
