defmodule Ultramoist.Positions do
  @moduledoc false

  def fetch(user, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    dex = Keyword.get(opts, :dex)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})

    request_opts = Keyword.merge(http_opts, base_url: base_url)
    body = Ultramoist.Dex.merge_dex(%{"type" => "clearinghouseState", "user" => user}, dex)

    with {:ok, %{"assetPositions" => positions}} <- http.info_request(body, request_opts) do
      {:ok, Enum.map(positions, &Ultramoist.Positions.Position.parse/1)}
    end
  end

  def parse(%{
        "marginSummary" => %{"accountValue" => account_value},
        "time" => time,
        "assetPositions" => asset_positions
      }) do
    %{
      positions: Enum.map(asset_positions, &Ultramoist.Positions.Position.parse/1),
      account_value: account_value,
      time: time
    }
  end
end
