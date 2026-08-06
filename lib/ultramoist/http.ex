defmodule Ultramoist.Http do
  @moduledoc false

  def info_request(body, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    unwrap(Req.post(base_url <> "/info", json: body))
  end

  def stats_request(type, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    unwrap(Req.get(base_url <> "/" <> type))
  end

  def exchange_request(action, opts) do
    base_url = Keyword.fetch!(opts, :base_url)
    signature = Keyword.fetch!(opts, :signature)
    nonce = Keyword.fetch!(opts, :nonce)
    vault_address = Keyword.fetch!(opts, :vault_address)

    body = %{
      "action" => action,
      "signature" => signature,
      "nonce" => nonce,
      "vaultAddress" => vault_address
    }

    unwrap(Req.post(base_url <> "/exchange", json: body))
  end

  defp unwrap({:ok, %Req.Response{body: response_body}}), do: {:ok, response_body}
  defp unwrap({:error, reason}), do: {:error, reason}
end
