defmodule Ultramoist.WebSocket.Transport do
  @moduledoc false

  @callback open(url :: String.t(), owner :: pid()) :: {:ok, term()} | {:error, term()}
  @callback send_frame(conn :: term(), frame :: String.t()) :: :ok
  @callback close(conn :: term()) :: :ok
end
