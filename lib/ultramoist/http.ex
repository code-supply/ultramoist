defmodule Ultramoist.Http do
  @moduledoc false

  @behaviour Ultramoist.Http.Client

  @impl true
  def info_request(body, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    unwrap(Req.post(base_url <> "/info", json: body))
  end

  @impl true
  def stats_request(type, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    unwrap(Req.get(base_url <> "/" <> type))
  end

  @impl true
  def exchange_request(action, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    signature = Keyword.fetch!(opts, :signature)
    nonce = Keyword.fetch!(opts, :nonce)
    vault_address = Keyword.fetch!(opts, :vault_address)

    body = %{
      "action" => to_json(action),
      "signature" => signature,
      "nonce" => nonce,
      "vaultAddress" => vault_address
    }

    unwrap(Req.post(base_url <> "/exchange", json: body))
  end

  defp to_json(keyword_list) when is_list(keyword_list) do
    if Keyword.keyword?(keyword_list) do
      Map.new(keyword_list, fn {key, value} -> {to_string(key), to_json(value)} end)
    else
      Enum.map(keyword_list, &to_json/1)
    end
  end

  defp to_json(value), do: value

  defp unwrap({:ok, %Req.Response{body: response_body}}), do: {:ok, response_body}
  defp unwrap({:error, reason}), do: {:error, reason}
end
