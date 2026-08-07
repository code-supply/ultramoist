defmodule Ultramoist.WebSocket.MintTransport do
  @moduledoc false

  @behaviour Ultramoist.WebSocket.Transport

  alias Ultramoist.WebSocket.MintTransport.Loop

  @impl true
  def open(url, owner) do
    uri = URI.parse(url)

    case Mint.HTTP.connect(:https, uri.host, uri.port) do
      {:ok, conn} -> upgrade(conn, uri.path, owner)
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def send_frame(conn, frame), do: GenServer.cast(conn, {:send_frame, frame})

  @impl true
  def close(conn), do: GenServer.stop(conn)

  defp upgrade(conn, path, owner) do
    case Mint.WebSocket.upgrade(:wss, conn, path, []) do
      {:ok, conn, ref} -> await_and_start_loop(conn, ref, owner)
      {:error, _conn, reason} -> {:error, reason}
    end
  end

  defp await_and_start_loop(conn, ref, owner) do
    case await_upgrade(conn, ref) do
      {:ok, conn, websocket} ->
        {:ok, loop_pid} =
          Loop.start_link(conn: conn, ref: ref, websocket: websocket, owner: owner)

        {:ok, ^conn} = Mint.HTTP.controlling_process(conn, loop_pid)
        send(owner, {:ws, loop_pid, :connected})
        {:ok, loop_pid}

      {:error, _conn, reason} ->
        {:error, reason}
    end
  end

  defp await_upgrade(conn, ref, acc \\ %{}) do
    receive do
      message ->
        case Mint.WebSocket.stream(conn, message) do
          {:ok, conn, responses} ->
            acc = collect_upgrade_responses(acc, ref, responses)

            if acc[:done] do
              Mint.WebSocket.new(conn, ref, acc[:status], acc[:headers] || [])
            else
              await_upgrade(conn, ref, acc)
            end

          {:error, conn, reason, _responses} ->
            {:error, conn, reason}

          :unknown ->
            await_upgrade(conn, ref, acc)
        end
    after
      5_000 -> {:error, conn, :timeout}
    end
  end

  defp collect_upgrade_responses(acc, ref, responses) do
    Enum.reduce(responses, acc, fn
      {:status, ^ref, status}, acc -> Map.put(acc, :status, status)
      {:headers, ^ref, headers}, acc -> Map.put(acc, :headers, headers)
      {:done, ^ref}, acc -> Map.put(acc, :done, true)
      _other, acc -> acc
    end)
  end
end
