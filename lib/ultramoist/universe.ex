defmodule Ultramoist.Universe do
  @moduledoc false

  # @spec SCAN-API-001
  def fetch(opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    dex = Keyword.get(opts, :dex)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})
    request_opts = Keyword.merge(http_opts, base_url: base_url)

    with {:ok, [%{"universe" => universe}, contexts]} <-
           http.info_request(request_body(dex), request_opts) do
      assets =
        universe
        |> Enum.zip(contexts)
        |> Enum.map(fn {meta, ctx} -> Ultramoist.Universe.Asset.parse(meta, ctx, dex) end)

      {:ok, assets}
    end
  end

  defp request_body(nil), do: %{"type" => "metaAndAssetCtxs"}
  defp request_body(dex), do: %{"type" => "metaAndAssetCtxs", "dex" => dex}
end
