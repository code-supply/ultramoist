defmodule Ultramoist.Http.Client do
  @moduledoc false

  @callback info_request(body :: map(), opts :: keyword()) :: {:ok, term()} | {:error, term()}
  @callback stats_request(type :: String.t(), opts :: keyword()) ::
              {:ok, term()} | {:error, term()}
  @callback exchange_request(action :: term(), opts :: keyword()) ::
              {:ok, term()} | {:error, term()}
end
