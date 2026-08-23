defmodule Ultramoist.Universe do
  @moduledoc false

  # @spec SCAN-API-001
  def fetch(opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})
    request_opts = Keyword.merge(http_opts, base_url: base_url)

    with {:ok, [%{"universe" => universe}, contexts]} <-
           http.info_request(%{"type" => "metaAndAssetCtxs"}, request_opts) do
      assets =
        universe
        |> Enum.zip(contexts)
        |> Enum.map(fn {meta, ctx} -> Ultramoist.Universe.Asset.parse(meta, ctx) end)

      {:ok, assets}
    end
  end
end
