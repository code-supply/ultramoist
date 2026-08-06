defmodule Ultramoist.AssetCache do
  @moduledoc false

  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, [], opts)

  def lookup(pid, coin), do: GenServer.call(pid, {:lookup, coin})

  @impl true
  def init([]) do
    {:ok, %{"universe" => universe}} =
      Ultramoist.Http.info_request(%{"type" => "meta"}, base_url: Ultramoist.Config.info_url())

    {:ok, build_index(universe)}
  end

  @impl true
  def handle_call({:lookup, coin}, _from, index) do
    {:reply, resolve(index, coin), index}
  end

  def build_index(universe) do
    universe
    |> Enum.with_index()
    |> Map.new(fn {%{"name" => name}, index} -> {name, index} end)
  end

  def resolve(index, coin) do
    case Map.fetch(index, coin) do
      {:ok, asset} -> {:ok, asset}
      :error -> {:error, :not_found}
    end
  end
end
