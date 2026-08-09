defmodule Ultramoist.Orders do
  @moduledoc false

  # @spec ORDS-API-001
  def fetch_open(user, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})

    request_opts = Keyword.merge(http_opts, base_url: base_url)

    with {:ok, orders} <-
           http.info_request(%{"type" => "openOrders", "user" => user}, request_opts) do
      {:ok, Enum.map(orders, &Ultramoist.Orders.OpenOrder.parse/1)}
    end
  end
end
