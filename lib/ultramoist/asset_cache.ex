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

    {:ok, %{"universe" => universe}} =
      http.info_request(%{"type" => "meta"}, Keyword.put(http_opts, :base_url, base_url))

    {:ok, build_index(universe)}
  end

  @impl true
  def handle_call({:lookup, coin}, _from, index) do
    {:reply, resolve(index, coin), index}
  end

  def build_index(universe) do
    universe
    |> Enum.with_index()
    |> Map.new(fn {%{"name" => name, "szDecimals" => size_decimals}, asset_index} ->
      {name, %{asset_index: asset_index, size_decimals: size_decimals}}
    end)
  end

  def resolve(index, coin) do
    case Map.fetch(index, coin) do
      {:ok, asset} -> {:ok, asset}
      :error -> {:error, :not_found}
    end
  end
end
