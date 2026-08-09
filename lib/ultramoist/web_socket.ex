defmodule Ultramoist.WebSocket do
  @moduledoc false

  use GenServer

  @backoff_delays [1_000, 2_000, 5_000, 10_000, 30_000, 60_000]

  # @spec WS-DATA-001
  def backoff_delay(attempt) do
    Enum.at(@backoff_delays, attempt, List.last(@backoff_delays))
  end

  def start_link(opts) do
    {gen_opts, init_opts} = Keyword.split(opts, [:name])
    GenServer.start_link(__MODULE__, init_opts, gen_opts)
  end

  def status(pid), do: GenServer.call(pid, :status)

  def subscribe(pid, key, subscription, callback) do
    GenServer.call(pid, {:subscribe, key, subscription, callback})
  end

  def unsubscribe(pid, key), do: GenServer.call(pid, {:unsubscribe, key})

  @impl true
  def init(opts) do
    url = Keyword.get_lazy(opts, :url, &Ultramoist.Config.web_socket_url/0)
    transport = Keyword.fetch!(opts, :transport)
    backoff_delay = Keyword.get(opts, :backoff_delay, &backoff_delay/1)

    state = %{
      url: url,
      transport: transport,
      conn: nil,
      status: :disconnected,
      reconnect_attempts: 0,
      backoff_delay: backoff_delay,
      subscriptions: %{}
    }

    {:ok, state, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, state) do
    {:ok, conn} = state.transport.open(state.url, self())
    {:noreply, %{state | conn: conn}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state.status, state}
  end

  # @spec WS-API-004
  @impl true
  def handle_call(
        {:subscribe, key, _subscription, _callback},
        _from,
        %{subscriptions: subs} = state
      )
      when is_map_key(subs, key) do
    {:reply, :ok, state}
  end

  # @spec SUB-API-001
  def handle_call({:subscribe, key, subscription, callback}, _from, state) do
    if state.status == :connected, do: send_envelope(state, "subscribe", subscription)

    entry = %{subscription: subscription, callback: callback}
    {:reply, :ok, %{state | subscriptions: Map.put(state.subscriptions, key, entry)}}
  end

  # @spec SUB-API-003
  @impl true
  def handle_call({:unsubscribe, key}, _from, state) do
    {entry, subscriptions} = Map.pop(state.subscriptions, key)

    if entry, do: send_envelope(state, "unsubscribe", entry.subscription)

    {:reply, :ok, %{state | subscriptions: subscriptions}}
  end

  # @spec WS-API-001
  # @spec WS-API-003
  @impl true
  def handle_info({:ws, conn, :connected}, %{conn: conn} = state) do
    Enum.each(state.subscriptions, fn {_key, %{subscription: subscription}} ->
      send_envelope(state, "subscribe", subscription)
    end)

    {:noreply, %{state | status: :connected, reconnect_attempts: 0}}
  end

  # @spec SUB-API-002
  @impl true
  def handle_info({:ws, conn, {:frame, text}}, %{conn: conn} = state) do
    message = JSON.decode!(text)

    Enum.each(state.subscriptions, fn {_key, %{subscription: subscription, callback: callback}} ->
      if subscription["type"] == message["channel"], do: callback.(message)
    end)

    {:noreply, state}
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

  defp send_envelope(state, method, subscription) do
    frame = JSON.encode!(%{"method" => method, "subscription" => subscription})
    state.transport.send_frame(state.conn, frame)
  end
end
