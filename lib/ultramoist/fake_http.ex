defmodule Ultramoist.FakeHttp do
  @moduledoc false

  @behaviour Ultramoist.Http.Client

  @impl true
  def info_request(body, opts), do: Keyword.fetch!(opts, :stub).(body, opts)

  @impl true
  def stats_request(type, opts), do: Keyword.fetch!(opts, :stub).(type, opts)

  @impl true
  def exchange_request(action, opts), do: Keyword.fetch!(opts, :stub).(action, opts)
end
