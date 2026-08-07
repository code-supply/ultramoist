defmodule Ultramoist.Config do
  @moduledoc false

  def info_url, do: info_url(chain())

  def info_url(chain) do
    case chain do
      :mainnet -> "https://api.hyperliquid.xyz"
      :testnet -> "https://api.hyperliquid-testnet.xyz"
    end
  end

  def stats_url, do: stats_url(chain())

  def stats_url(chain) do
    case chain do
      :mainnet -> "https://stats-data.hyperliquid.xyz/Mainnet"
      :testnet -> "https://stats-data.hyperliquid.xyz/Testnet"
    end
  end

  defp chain, do: Application.fetch_env!(:ultramoist, :chain)
end
