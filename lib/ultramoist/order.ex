defmodule Ultramoist.Order do
  @moduledoc false

  # @spec ORD-DATA-001
  def build_place_action(asset_index, is_buy, limit_px, sz) do
    [
      type: "order",
      orders: [
        [a: asset_index, b: is_buy, p: limit_px, s: sz, r: false, t: [limit: [tif: "Gtc"]]]
      ],
      grouping: "na"
    ]
  end

  # @spec ORD-DATA-002
  def parse_place_response(%{
        "response" => %{"data" => %{"statuses" => [%{"resting" => %{"oid" => order_id}}]}}
      }) do
    {:ok, order_id}
  end

  def parse_place_response(%{
        "response" => %{"data" => %{"statuses" => [%{"error" => reason}]}}
      }) do
    {:error, reason}
  end

  # @spec ORD-DATA-004
  def build_cancel_action(asset_index, order_id) do
    [type: "cancel", cancels: [[a: asset_index, o: order_id]]]
  end

  # @spec ORD-DATA-005
  def parse_cancel_response(%{"response" => %{"data" => %{"statuses" => ["success"]}}}) do
    :ok
  end

  # @spec ORD-API-001
  def place_limit(cache_pid, coin, is_buy, limit_px, sz, opts) do
    with {:ok, asset_index} <- Ultramoist.AssetCache.lookup(cache_pid, coin) do
      action = build_place_action(asset_index, is_buy, limit_px, sz)

      priv_key = Keyword.fetch!(opts, :priv_key)
      source = Keyword.fetch!(opts, :source)
      vault_address = Keyword.get(opts, :vault_address)
      nonce = System.system_time(:millisecond)

      {signature_r, signature_s, recovery_v} =
        Ultramoist.Signer.sign_l1_action(action,
          nonce: nonce,
          source: source,
          priv_key: priv_key,
          vault_address: vault_address
        )

      signature = %{
        "r" => "0x" <> Base.encode16(signature_r, case: :lower),
        "s" => "0x" <> Base.encode16(signature_s, case: :lower),
        "v" => recovery_v
      }

      http_opts =
        opts
        |> Keyword.drop([:priv_key, :source, :vault_address])
        |> Keyword.merge(signature: signature, nonce: nonce, vault_address: vault_address)

      with {:ok, response} <- Ultramoist.Http.exchange_request(action, http_opts) do
        parse_place_response(response)
      end
    end
  end
end
