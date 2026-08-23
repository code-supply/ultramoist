defmodule Ultramoist.Candles do
  @moduledoc false

  # @spec CNDL-API-001
  # @spec SCAN-API-003a
  def fetch(coin, interval, start_time, end_time, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})
    request_opts = Keyword.merge(http_opts, base_url: base_url)

    body = %{
      "type" => "candleSnapshot",
      "req" => %{
        "coin" => coin,
        "interval" => interval,
        "startTime" => start_time,
        "endTime" => end_time
      }
    }

    case http.info_request(body, request_opts) do
      {:ok, nil} -> {:error, :not_found}
      {:ok, candles} -> {:ok, Enum.map(candles, &Ultramoist.Candle.parse/1)}
      {:error, reason} -> {:error, reason}
    end
  end
end
