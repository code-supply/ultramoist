defmodule Ultramoist.Vaults do
  @moduledoc false

  def fetch_fills(user, start_time, end_time, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})

    request_opts = Keyword.merge(http_opts, base_url: base_url)

    body = %{
      "type" => "userFillsByTime",
      "user" => user,
      "startTime" => start_time,
      "endTime" => end_time
    }

    with {:ok, fills} <- http.info_request(body, request_opts) do
      {:ok, Enum.map(fills, &Ultramoist.Fill.parse/1)}
    end
  end

  def fetch_funding(user, start_time, end_time, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})

    request_opts = Keyword.merge(http_opts, base_url: base_url)

    body = %{
      "type" => "userFunding",
      "user" => user,
      "startTime" => start_time,
      "endTime" => end_time
    }

    with {:ok, payments} <- http.info_request(body, request_opts) do
      {:ok, Enum.map(payments, &Ultramoist.FundingPayment.parse/1)}
    end
  end

  def fetch_details(vault_address, user, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})

    request_opts = Keyword.merge(http_opts, base_url: base_url)
    body = %{"type" => "vaultDetails", "vaultAddress" => vault_address, "user" => user}

    with {:ok, details} <- http.info_request(body, request_opts) do
      {:ok, Ultramoist.VaultDetails.parse(details)}
    end
  end

  def fetch_summaries(opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})

    with {:ok, vaults} <-
           http.stats_request("vaults", Keyword.merge(http_opts, base_url: base_url)) do
      {:ok, Enum.map(vaults, &Ultramoist.VaultSummary.parse/1)}
    end
  end

  def fetch_equities(user, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})

    request_opts = Keyword.merge(http_opts, base_url: base_url)
    http.info_request(%{"type" => "userVaultEquities", "user" => user}, request_opts)
  end

  def fetch_ledger_updates(user, start_time, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})

    request_opts = Keyword.merge(http_opts, base_url: base_url)
    body = %{"type" => "userNonFundingLedgerUpdates", "user" => user, "startTime" => start_time}

    http.info_request(body, request_opts)
  end
end
