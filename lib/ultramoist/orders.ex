defmodule Ultramoist.Orders do
  @moduledoc false

  # @spec ORDS-API-001
  # @spec ORDS-API-002
  def fetch_open(user, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    dex = Keyword.get(opts, :dex)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})

    request_opts = Keyword.merge(http_opts, base_url: base_url)
    body = Ultramoist.Dex.merge_dex(%{"type" => "frontendOpenOrders", "user" => user}, dex)

    with {:ok, orders} <- http.info_request(body, request_opts) do
      {:ok, Enum.map(orders || [], &Ultramoist.Orders.OpenOrder.parse/1)}
    end
  end
end
