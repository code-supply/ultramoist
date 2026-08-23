defmodule Ultramoist.Book do
  @moduledoc false

  # @spec SCAN-API-002
  # @spec SCAN-API-002a
  def fetch(coin, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})
    request_opts = Keyword.merge(http_opts, base_url: base_url)

    with {:ok, %{"levels" => [bids, asks]}} <-
           http.info_request(%{"type" => "l2Book", "coin" => coin}, request_opts) do
      {:ok,
       %{
         bids: Enum.map(bids, &Ultramoist.Book.Level.parse/1),
         asks: Enum.map(asks, &Ultramoist.Book.Level.parse/1)
       }}
    else
      {:ok, nil} -> {:error, :not_found}
    end
  end
end
