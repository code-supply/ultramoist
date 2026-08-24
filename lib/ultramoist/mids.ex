defmodule Ultramoist.Mids do
  @moduledoc false

  def fetch(coin, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})
    request_opts = Keyword.merge(http_opts, base_url: base_url)

    with {:ok, mids} <- http.info_request(%{"type" => "allMids"}, request_opts),
         {:ok, price} <- fetch_price(mids, coin) do
      {:ok, Decimal.new(price)}
    else
      _ -> {:error, :not_found}
    end
  end

  defp fetch_price(mids, coin) when is_map(mids), do: Map.fetch(mids, coin)
  defp fetch_price(_mids, _coin), do: :error
end
