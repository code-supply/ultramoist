defmodule Ultramoist.Universe do
  @moduledoc false

  # @spec SCAN-API-001
  def fetch(opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    dex = Keyword.get(opts, :dex)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})
    request_opts = Keyword.merge(http_opts, base_url: base_url)

    body = Ultramoist.Dex.merge_dex(%{"type" => "metaAndAssetCtxs"}, dex)

    with {:ok, [%{"universe" => universe}, contexts]} <- http.info_request(body, request_opts) do
      assets =
        universe
        |> Enum.zip(contexts)
        |> Enum.map(fn {meta, ctx} -> Ultramoist.Universe.Asset.parse(meta, ctx, dex) end)

      {:ok, assets}
    end
  end
end
