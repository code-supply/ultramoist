defmodule Ultramoist.Portfolio do
  @moduledoc false

  def fetch(user, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})
    request_opts = Keyword.merge(http_opts, base_url: base_url)

    with {:ok, periods} <-
           http.info_request(%{"type" => "portfolio", "user" => user}, request_opts) do
      {:ok, Map.new(periods, fn [period, histories] -> {period, parse(histories)} end)}
    end
  end

  defp parse(histories) do
    %{
      account_value_history: series(histories["accountValueHistory"]),
      pnl_history: series(histories["pnlHistory"])
    }
  end

  defp series(points) do
    Enum.map(points, fn [time, value] ->
      {Ultramoist.Timestamp.parse(time), Decimal.new(value)}
    end)
  end
end
