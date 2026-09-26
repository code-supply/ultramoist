defmodule Ultramoist.AssetCache do
  @moduledoc false

  use GenServer

  def start_link(opts) do
    {gen_opts, init_opts} = Keyword.split(opts, [:name])
    GenServer.start_link(__MODULE__, init_opts, gen_opts)
  end

  def lookup(pid, coin), do: GenServer.call(pid, {:lookup, coin})

  @impl true
  def init(init_opts) do
    base_url = Keyword.get_lazy(init_opts, :base_url, &Ultramoist.Config.info_url/0)
    {http, http_opts} = Keyword.get(init_opts, :http, {Ultramoist.Http, []})
    dexs = Keyword.get(init_opts, :dexs, [nil])
    request_opts = Keyword.put(http_opts, :base_url, base_url)

    perp_dex_indices = perp_dex_indices(dexs, http, request_opts)

    index =
      dexs
      |> Enum.map(fn dex ->
        {:ok, %{"universe" => universe}} = http.info_request(meta_body(dex), request_opts)
        build_index(universe, Map.get(perp_dex_indices, dex))
      end)
      |> Enum.reduce(&Map.merge/2)

    {:ok, index}
  end

  @impl true
  def handle_call({:lookup, coin}, _from, index) do
    {:reply, resolve(index, coin), index}
  end

  def build_index(universe, perp_dex_index \\ nil) do
    offset = Ultramoist.Dex.asset_id_offset(perp_dex_index)

    universe
    |> Enum.with_index()
    |> Map.new(fn {%{"name" => name, "szDecimals" => size_decimals}, local_index} ->
      {name, %{asset_index: offset + local_index, size_decimals: size_decimals}}
    end)
  end

  defp meta_body(nil), do: %{"type" => "meta"}
  defp meta_body(dex), do: %{"type" => "meta", "dex" => dex}

  defp perp_dex_indices(dexs, http, request_opts) do
    if Enum.any?(dexs, & &1) do
      {:ok, perp_dexs} = http.info_request(%{"type" => "perpDexs"}, request_opts)

      dexs
      |> Enum.filter(& &1)
      |> Map.new(fn dex ->
        {:ok, index} = Ultramoist.Dex.index_of(perp_dexs, dex)
        {dex, index}
      end)
    else
      %{}
    end
  end

  def resolve(index, coin) do
    case Map.fetch(index, coin) do
      {:ok, asset} -> {:ok, asset}
      :error -> {:error, :not_found}
    end
  end
end
