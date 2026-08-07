defmodule Ultramoist.WebSocket do
  @moduledoc false

  use GenServer

  @backoff_delays [1_000, 2_000, 5_000, 10_000, 30_000, 60_000]

  # @spec WS-DATA-001
  def backoff_delay(attempt) do
    Enum.at(@backoff_delays, attempt, List.last(@backoff_delays))
  end

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  def status(pid), do: GenServer.call(pid, :status)

  @impl true
  def init(opts) do
    url = Keyword.fetch!(opts, :url)
    transport = Keyword.fetch!(opts, :transport)
    backoff_delay = Keyword.get(opts, :backoff_delay, &backoff_delay/1)

    {:ok, conn} = transport.open(url, self())

    {:ok,
     %{
       url: url,
       transport: transport,
       conn: conn,
       status: :disconnected,
       reconnect_attempts: 0,
       backoff_delay: backoff_delay
     }}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state.status, state}
  end

  # @spec WS-API-001
  @impl true
  def handle_info({:ws, conn, :connected}, %{conn: conn} = state) do
    {:noreply, %{state | status: :connected, reconnect_attempts: 0}}
  end

  # @spec WS-API-002
  @impl true
  def handle_info({:ws, conn, :disconnected}, %{conn: conn} = state) do
    delay = state.backoff_delay.(state.reconnect_attempts)
    Process.send_after(self(), :reconnect, delay)
    {:noreply, %{state | status: :reconnecting, reconnect_attempts: state.reconnect_attempts + 1}}
  end

  def handle_info(:reconnect, state) do
    {:ok, conn} = state.transport.open(state.url, self())
    {:noreply, %{state | conn: conn}}
  end
end
