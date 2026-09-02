defmodule Ultramoist.Vaults do
  @moduledoc false

  # Hyperliquid's userFillsByTime endpoint returns at most this many fills
  # per request; a full page means there may be more fills to fetch.
  @fills_page_cap 2000

  # Hyperliquid's userFunding endpoint returns at most this many records per
  # request; a full page means there may be more funding payments to fetch.
  @funding_page_cap 500

  def fetch_fills(user, start_time, end_time, opts) do
    raw_pages =
      Stream.unfold({:continue, start_time}, &fetch_next_fills_page(user, end_time, opts, &1))
      |> Enum.to_list()

    {:ok, merge_fill_pages(raw_pages)}
  end

  def fill_pagination_state(page) do
    if length(page) == @fills_page_cap do
      {:continue, page |> List.last() |> Map.fetch!(:time) |> to_unix_ms()}
    else
      :stop
    end
  end

  def merge_fill_pages(pages) do
    pages
    |> List.flatten()
    |> Enum.uniq_by(& &1.trade_id)
  end

  def fetch_funding(user, start_time, end_time, opts) do
    raw_pages =
      Stream.unfold(
        {:continue, start_time},
        &fetch_next_funding_page(user, end_time, opts, &1)
      )
      |> Enum.to_list()

    {:ok, merge_funding_pages(raw_pages)}
  end

  def funding_pagination_state(page) do
    if length(page) == @funding_page_cap do
      {:continue, page |> List.last() |> Map.fetch!(:time) |> to_unix_ms()}
    else
      :stop
    end
  end

  def merge_funding_pages(pages) do
    pages
    |> List.flatten()
    |> Enum.uniq_by(&{&1.time, &1.coin})
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

  defp fetch_next_fills_page(_user, _end_time, _opts, :stop), do: nil

  defp fetch_next_fills_page(user, end_time, opts, {:continue, start_time}) do
    {:ok, page} = fetch_fills_page(user, start_time, end_time, opts)
    {page, fill_pagination_state(page)}
  end

  defp fetch_fills_page(user, start_time, end_time, opts) do
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

  defp fetch_next_funding_page(_user, _end_time, _opts, :stop), do: nil

  defp fetch_next_funding_page(user, end_time, opts, {:continue, start_time}) do
    {:ok, page} = fetch_funding_page(user, start_time, end_time, opts)
    {page, funding_pagination_state(page)}
  end

  defp fetch_funding_page(user, start_time, end_time, opts) do
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

  defp to_unix_ms(naive_date_time),
    do: NaiveDateTime.diff(naive_date_time, ~N[1970-01-01 00:00:00], :millisecond)
end
