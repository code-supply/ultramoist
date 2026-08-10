defmodule Ultramoist.Positions do
  @moduledoc false

  def fetch(user, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})

    request_opts = Keyword.merge(http_opts, base_url: base_url)

    with {:ok, %{"assetPositions" => positions}} <-
           http.info_request(%{"type" => "clearinghouseState", "user" => user}, request_opts) do
      {:ok, Enum.map(positions, &Ultramoist.Positions.Position.parse/1)}
    end
  end
end
