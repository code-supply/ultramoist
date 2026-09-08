defmodule Ultramoist.FakeTransport do
  @moduledoc false

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
