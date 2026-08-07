defmodule Ultramoist.WebSocket.MintTransport.Loop do
  @moduledoc false

  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  @impl true
  def init(opts) do
    {:ok,
     %{
       conn: Keyword.fetch!(opts, :conn),
       ref: Keyword.fetch!(opts, :ref),
       websocket: Keyword.fetch!(opts, :websocket),
       owner: Keyword.fetch!(opts, :owner)
     }}
  end

  @impl true
  def handle_cast({:send_frame, frame}, state) do
    {:ok, websocket, data} = Mint.WebSocket.encode(state.websocket, {:text, frame})
    {:ok, conn} = Mint.WebSocket.stream_request_body(state.conn, state.ref, data)
    {:noreply, %{state | conn: conn, websocket: websocket}}
  end

  @impl true
  def handle_info(message, state) do
    case Mint.WebSocket.stream(state.conn, message) do
      {:ok, conn, responses} ->
        {:noreply, handle_responses(responses, %{state | conn: conn})}

      {:error, conn, _reason, _responses} ->
        send(state.owner, {:ws, self(), :disconnected})
        {:noreply, %{state | conn: conn}}

      :unknown ->
        {:noreply, state}
    end
  end

  @impl true
  def terminate(_reason, state) do
    Mint.HTTP.close(state.conn)
    :ok
  end

  defp handle_responses(responses, state) do
    ref = state.ref

    Enum.reduce(responses, state, fn
      {:data, ^ref, data}, acc ->
        {:ok, websocket, frames} = Mint.WebSocket.decode(acc.websocket, data)
        Enum.each(frames, &forward_frame(&1, acc.owner))
        %{acc | websocket: websocket}

      _other, acc ->
        acc
    end)
  end

  defp forward_frame({:text, text}, owner), do: send(owner, {:ws, self(), {:frame, text}})

  defp forward_frame({:close, _code, _reason}, owner),
    do: send(owner, {:ws, self(), :disconnected})

  defp forward_frame(_other, _owner), do: :ok
end
