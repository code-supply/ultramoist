defmodule Ultramoist.WebSocketTest do
  use ExUnit.Case, async: true

  defmodule TestTransport do
    @behaviour Ultramoist.WebSocket.Transport

    def start(test_pid, opts \\ []) do
      auto_connect = Keyword.get(opts, :auto_connect, true)
      fail_next_open = Keyword.get(opts, :fail_next_open, false)

      {:ok, pid} =
        result =
        Agent.start_link(
          fn ->
            %{
              conn: nil,
              test_pid: test_pid,
              auto_connect: auto_connect,
              fail_next_open: fail_next_open
            }
          end,
          name: __MODULE__
        )

      ExUnit.Callbacks.on_exit(fn ->
        try do
          Agent.stop(pid)
        catch
          :exit, _ -> :ok
        end
      end)

      result
    end

    @impl true
    def open(url, owner) do
      %{test_pid: test_pid, auto_connect: auto_connect, fail_next_open: fail_next_open} =
        Agent.get_and_update(__MODULE__, fn s -> {s, %{s | fail_next_open: false}} end)

      if fail_next_open do
        send(test_pid, {:transport_open_failed, url})
        {:error, :connection_refused}
      else
        conn = make_ref()
        Agent.update(__MODULE__, &%{&1 | conn: conn})

        if auto_connect, do: send(owner, {:ws, conn, :connected})
        send(test_pid, {:transport_opened, conn, url})

        {:ok, conn}
      end
    end

    def fail_next_open, do: Agent.update(__MODULE__, &%{&1 | fail_next_open: true})

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

    assert_receive {:transport_opened, _conn, _url}
    assert Ultramoist.WebSocket.status(pid) == :connected
  end

  # @spec WS-API-007
  test "can be started under a registered name for other processes to call into" do
    {:ok, _agent} = TestTransport.start(self())

    {:ok, _pid} =
      Ultramoist.WebSocket.start_link(
        name: __MODULE__.NamedSocket,
        url: "ws://fake",
        transport: TestTransport
      )

    assert_receive {:transport_opened, _conn, _url}
    assert Ultramoist.WebSocket.status(__MODULE__.NamedSocket) == :connected
  end

  # @spec WS-API-008
  test "defaults to the configured Hyperliquid WebSocket URL when none is given" do
    Application.put_env(:ultramoist, :chain, :testnet)
    on_exit(fn -> Application.delete_env(:ultramoist, :chain) end)

    {:ok, _agent} = TestTransport.start(self())

    {:ok, _pid} = Ultramoist.WebSocket.start_link(transport: TestTransport)

    assert_receive {:transport_opened, _conn, "wss://api.hyperliquid-testnet.xyz/ws"}
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

    assert_receive {:transport_opened, conn, _url}

    send(pid, {:ws, conn, :disconnected})
    assert Ultramoist.WebSocket.status(pid) == :reconnecting

    assert_receive {:transport_opened, _reconnected_conn, _url}
    assert Ultramoist.WebSocket.status(pid) == :connected
  end

  # @spec WS-API-010
  test "schedules another backoff retry instead of crashing when a reconnect attempt fails" do
    {:ok, _agent} = TestTransport.start(self())

    {:ok, pid} =
      Ultramoist.WebSocket.start_link(
        url: "ws://fake",
        transport: TestTransport,
        backoff_delay: fn _attempt -> 0 end
      )

    assert_receive {:transport_opened, conn, _url}

    TestTransport.fail_next_open()
    send(pid, {:ws, conn, :disconnected})

    assert_receive {:transport_open_failed, _url}
    assert Process.alive?(pid)
    assert Ultramoist.WebSocket.status(pid) == :reconnecting

    assert_receive {:transport_opened, _reconnected_conn, _url}
    assert Ultramoist.WebSocket.status(pid) == :connected
  end

  # @spec WS-API-009
  test "ignores a stale event from a superseded connection instead of crashing" do
    {:ok, _agent} = TestTransport.start(self())
    {:ok, pid} = Ultramoist.WebSocket.start_link(url: "ws://fake", transport: TestTransport)

    assert_receive {:transport_opened, _conn, _url}
    assert Ultramoist.WebSocket.status(pid) == :connected

    send(pid, {:ws, make_ref(), :disconnected})

    assert Process.alive?(pid)
    assert Ultramoist.WebSocket.status(pid) == :connected
  end

  # @spec WS-API-004
  test "subscribing with an existing key is a no-op" do
    {:ok, _agent} = TestTransport.start(self())
    {:ok, pid} = Ultramoist.WebSocket.start_link(url: "ws://fake", transport: TestTransport)

    callback = fn _message -> :ok end
    subscription = %{"type" => "userFills"}

    assert :ok = Ultramoist.WebSocket.subscribe(pid, "user_fills", subscription, callback)
    assert_receive {:frame_sent, _frame}

    assert :ok = Ultramoist.WebSocket.subscribe(pid, "user_fills", subscription, callback)
    refute_receive {:frame_sent, _}
  end

  # @spec SUB-API-004
  test "sends the subscribe envelope only once when a second key subscribes with identical content" do
    {:ok, _agent} = TestTransport.start(self())
    {:ok, pid} = Ultramoist.WebSocket.start_link(url: "ws://fake", transport: TestTransport)

    callback = fn _message -> :ok end
    subscription = %{"type" => "userFills", "user" => "0xabc"}

    assert :ok = Ultramoist.WebSocket.subscribe(pid, {:tab, 1}, subscription, callback)
    assert_receive {:frame_sent, _frame}

    assert :ok = Ultramoist.WebSocket.subscribe(pid, {:tab, 2}, subscription, callback)
    refute_receive {:frame_sent, _}
  end

  # @spec SUB-API-005
  test "sends the unsubscribe envelope only after the last subscriber for that content unsubscribes" do
    {:ok, _agent} = TestTransport.start(self())
    {:ok, pid} = Ultramoist.WebSocket.start_link(url: "ws://fake", transport: TestTransport)

    callback = fn _message -> :ok end
    subscription = %{"type" => "userFills", "user" => "0xabc"}

    :ok = Ultramoist.WebSocket.subscribe(pid, {:tab, 1}, subscription, callback)
    assert_receive {:frame_sent, _subscribe_frame}
    :ok = Ultramoist.WebSocket.subscribe(pid, {:tab, 2}, subscription, callback)

    assert :ok = Ultramoist.WebSocket.unsubscribe(pid, {:tab, 1})
    refute_receive {:frame_sent, _}

    assert :ok = Ultramoist.WebSocket.unsubscribe(pid, {:tab, 2})
    assert_receive {:frame_sent, frame}
    assert JSON.decode!(frame) == %{"method" => "unsubscribe", "subscription" => subscription}
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

    assert_receive {:transport_opened, conn, _url}

    callback = fn _message -> :ok end
    subscription = %{"type" => "userFills"}

    assert :ok = Ultramoist.WebSocket.subscribe(pid, "user_fills", subscription, callback)
    assert_receive {:frame_sent, _frame}

    send(pid, {:ws, conn, :disconnected})
    assert_receive {:transport_opened, _reconnected_conn, _url}

    assert_receive {:frame_sent, _frame}
  end

  # @spec WS-API-003
  test "resubscribes only once per unique content after reconnecting, even with multiple local subscribers" do
    {:ok, _agent} = TestTransport.start(self())

    {:ok, pid} =
      Ultramoist.WebSocket.start_link(
        url: "ws://fake",
        transport: TestTransport,
        backoff_delay: fn _attempt -> 0 end
      )

    assert_receive {:transport_opened, conn, _url}

    callback = fn _message -> :ok end
    subscription = %{"type" => "userFills"}

    :ok = Ultramoist.WebSocket.subscribe(pid, {:tab, 1}, subscription, callback)
    assert_receive {:frame_sent, _frame}
    :ok = Ultramoist.WebSocket.subscribe(pid, {:tab, 2}, subscription, callback)
    refute_receive {:frame_sent, _}

    send(pid, {:ws, conn, :disconnected})
    assert_receive {:transport_opened, _reconnected_conn, _url}

    assert_receive {:frame_sent, _frame}
    refute_receive {:frame_sent, _}
  end

  # @spec SUB-API-006
  test "replays the last matching message to a subscriber who joins existing content" do
    {:ok, _agent} = TestTransport.start(self())
    {:ok, pid} = Ultramoist.WebSocket.start_link(url: "ws://fake", transport: TestTransport)

    assert_receive {:transport_opened, conn, _url}

    test_pid = self()
    callback1 = fn message -> send(test_pid, {:callback1_invoked, message}) end
    callback2 = fn message -> send(test_pid, {:callback2_invoked, message}) end
    subscription = %{"type" => "clearinghouseState", "user" => "0xabc", "dex" => ""}

    :ok = Ultramoist.WebSocket.subscribe(pid, {:tab, 1}, subscription, callback1)
    assert_receive {:frame_sent, _frame}

    incoming =
      JSON.encode!(%{
        "channel" => "clearinghouseState",
        "data" => %{"user" => "0xabc", "dex" => "", "clearinghouseState" => %{}}
      })

    send(pid, {:ws, conn, {:frame, incoming}})
    assert_receive {:callback1_invoked, _message}

    :ok = Ultramoist.WebSocket.subscribe(pid, {:tab, 2}, subscription, callback2)
    refute_receive {:frame_sent, _}

    assert_receive {:callback2_invoked, decoded}
    assert decoded == JSON.decode!(incoming)
  end

  # @spec SUB-API-007
  test "does not replay stale data to a new subscriber after every previous subscriber for that content has left" do
    {:ok, _agent} = TestTransport.start(self())
    {:ok, pid} = Ultramoist.WebSocket.start_link(url: "ws://fake", transport: TestTransport)

    assert_receive {:transport_opened, conn, _url}

    test_pid = self()
    callback1 = fn message -> send(test_pid, {:callback1_invoked, message}) end
    callback2 = fn message -> send(test_pid, {:callback2_invoked, message}) end
    subscription = %{"type" => "clearinghouseState", "user" => "0xabc", "dex" => ""}

    :ok = Ultramoist.WebSocket.subscribe(pid, {:tab, 1}, subscription, callback1)
    assert_receive {:frame_sent, _subscribe_frame}

    incoming =
      JSON.encode!(%{
        "channel" => "clearinghouseState",
        "data" => %{"user" => "0xabc", "dex" => "", "clearinghouseState" => %{}}
      })

    send(pid, {:ws, conn, {:frame, incoming}})
    assert_receive {:callback1_invoked, _message}

    :ok = Ultramoist.WebSocket.unsubscribe(pid, {:tab, 1})
    assert_receive {:frame_sent, _unsubscribe_frame}

    :ok = Ultramoist.WebSocket.subscribe(pid, {:tab, 2}, subscription, callback2)
    assert_receive {:frame_sent, _fresh_subscribe_frame}
    refute_receive {:callback2_invoked, _}
  end

  # @spec SUB-API-001
  test "subscribe wraps the subscription in an envelope, sends it, and stores the callback" do
    {:ok, _agent} = TestTransport.start(self())
    {:ok, pid} = Ultramoist.WebSocket.start_link(url: "ws://fake", transport: TestTransport)

    assert_receive {:transport_opened, _conn, _url}

    callback = fn _message -> :ok end
    subscription = %{"type" => "userFills", "user" => "0xabc"}

    assert :ok = Ultramoist.WebSocket.subscribe(pid, "userFills:0xabc", subscription, callback)

    assert_receive {:frame_sent, frame}
    assert JSON.decode!(frame) == %{"method" => "subscribe", "subscription" => subscription}
  end

  # @spec SUB-API-002
  test "invokes the matching subscription's callback when a message arrives" do
    {:ok, _agent} = TestTransport.start(self())
    {:ok, pid} = Ultramoist.WebSocket.start_link(url: "ws://fake", transport: TestTransport)

    assert_receive {:transport_opened, conn, _url}

    test_pid = self()
    callback = fn message -> send(test_pid, {:callback_invoked, message}) end
    subscription = %{"type" => "userFills", "user" => "0xabc"}

    assert :ok = Ultramoist.WebSocket.subscribe(pid, "userFills:0xabc", subscription, callback)
    assert_receive {:frame_sent, _frame}

    incoming =
      JSON.encode!(%{"channel" => "userFills", "data" => %{"fills" => [], "user" => "0xabc"}})

    send(pid, {:ws, conn, {:frame, incoming}})

    assert_receive {:callback_invoked,
                    %{"channel" => "userFills", "data" => %{"fills" => [], "user" => "0xabc"}}}
  end

  # @spec SUB-API-005
  test "does not invoke a same-type subscription's callback when a message arrives for a different user" do
    {:ok, _agent} = TestTransport.start(self())
    {:ok, pid} = Ultramoist.WebSocket.start_link(url: "ws://fake", transport: TestTransport)

    assert_receive {:transport_opened, conn, _url}

    test_pid = self()
    callback = fn message -> send(test_pid, {:callback_invoked, message}) end
    subscription = %{"type" => "clearinghouseState", "user" => "0xabc", "dex" => ""}

    assert :ok =
             Ultramoist.WebSocket.subscribe(
               pid,
               "clearinghouseState:0xabc",
               subscription,
               callback
             )

    assert_receive {:frame_sent, _frame}

    incoming =
      JSON.encode!(%{
        "channel" => "clearinghouseState",
        "data" => %{"user" => "0xother", "dex" => "", "clearinghouseState" => %{}}
      })

    send(pid, {:ws, conn, {:frame, incoming}})

    refute_receive {:callback_invoked, _}
  end

  # @spec SUB-API-003
  test "unsubscribe removes the subscription and sends an unsubscribe envelope" do
    {:ok, _agent} = TestTransport.start(self())
    {:ok, pid} = Ultramoist.WebSocket.start_link(url: "ws://fake", transport: TestTransport)

    assert_receive {:transport_opened, _conn, _url}

    callback = fn _message -> :ok end
    subscription = %{"type" => "userFills", "user" => "0xabc"}

    assert :ok = Ultramoist.WebSocket.subscribe(pid, "userFills:0xabc", subscription, callback)
    assert_receive {:frame_sent, _subscribe_frame}

    assert :ok = Ultramoist.WebSocket.unsubscribe(pid, "userFills:0xabc")

    assert_receive {:frame_sent, frame}
    assert JSON.decode!(frame) == %{"method" => "unsubscribe", "subscription" => subscription}
  end

  # @spec SUB-API-004
  test "does not invoke the callback for a subscription that has been unsubscribed" do
    {:ok, _agent} = TestTransport.start(self())
    {:ok, pid} = Ultramoist.WebSocket.start_link(url: "ws://fake", transport: TestTransport)

    assert_receive {:transport_opened, conn, _url}

    test_pid = self()
    callback = fn message -> send(test_pid, {:callback_invoked, message}) end
    subscription = %{"type" => "userFills", "user" => "0xabc"}

    assert :ok = Ultramoist.WebSocket.subscribe(pid, "userFills:0xabc", subscription, callback)
    assert_receive {:frame_sent, _subscribe_frame}

    assert :ok = Ultramoist.WebSocket.unsubscribe(pid, "userFills:0xabc")
    assert_receive {:frame_sent, _unsubscribe_frame}

    incoming = JSON.encode!(%{"channel" => "userFills", "data" => %{"fills" => []}})
    send(pid, {:ws, conn, {:frame, incoming}})

    refute_receive {:callback_invoked, _}
  end

  # @spec WS-API-006
  test "connects to the real testnet WebSocket endpoint" do
    {:ok, conn} =
      Ultramoist.WebSocket.MintTransport.open(Ultramoist.Config.web_socket_url(:testnet), self())

    assert_receive {:ws, ^conn, :connected}

    Ultramoist.WebSocket.MintTransport.send_frame(conn, JSON.encode!(%{"method" => "ping"}))

    assert_receive {:ws, ^conn, {:frame, response}}, 5_000
    assert %{"channel" => "pong"} = JSON.decode!(response)
  end

  test "leaves unrelated messages in the mailbox instead of consuming them while awaiting the WebSocket upgrade" do
    send(self(), :unrelated_message)

    {:ok, conn} =
      Ultramoist.WebSocket.MintTransport.open(Ultramoist.Config.web_socket_url(:testnet), self())

    assert_receive {:ws, ^conn, :connected}
    assert_receive :unrelated_message
  end
end
