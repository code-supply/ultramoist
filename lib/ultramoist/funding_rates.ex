defmodule Ultramoist.FundingRates do
  @moduledoc false

  def fetch(coin, start_time, end_time, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})
    page_pause = Keyword.get(opts, :page_pause, fn -> :ok end)
    request_opts = Keyword.merge(http_opts, base_url: base_url)

    request_page = fn page_start ->
      if page_start != start_time, do: page_pause.()

      body = %{
        "type" => "fundingHistory",
        "coin" => coin,
        "startTime" => page_start,
        "endTime" => end_time
      }

      http.info_request(body, request_opts)
    end

    with {:ok, entries} <- fetch_pages(request_page, start_time, end_time, []) do
      {:ok, Enum.map(entries, &Ultramoist.FundingRate.parse/1)}
    end
  end

  defp fetch_pages(request_page, page_start, end_time, received) do
    case request_page.(page_start) do
      {:ok, []} ->
        {:ok, received}

      {:ok, page} ->
        last_time = List.last(page)["time"]
        received = received ++ page

        if last_time >= end_time,
          do: {:ok, received},
          else: fetch_pages(request_page, last_time + 1, end_time, received)

      {:error, _reason} = error ->
        error
    end
  end
end
