defmodule Ultramoist.Orders.Order do
  @moduledoc false

  require Logger

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

  # @spec ORD-DATA-006
  def parse_place_response(%{
        "response" => %{"data" => %{"statuses" => [%{"filled" => %{"oid" => order_id}}]}}
      }) do
    {:ok, order_id}
  end

  # @spec LEV-DATA-001
  def build_update_leverage_action(opts) do
    [
      type: "updateLeverage",
      asset: Keyword.fetch!(opts, :asset_index),
      isCross: Keyword.fetch!(opts, :is_cross),
      leverage: Keyword.fetch!(opts, :leverage)
    ]
  end

  # @spec LEV-DATA-001
  def parse_update_leverage_response(%{"response" => %{"type" => "default"}}) do
    :ok
  end

  def parse_update_leverage_response(%{"status" => "err", "response" => reason}) do
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

  # @spec ORD-DATA-007
  def parse_cancel_response(%{
        "response" => %{"data" => %{"statuses" => [%{"error" => reason}]}}
      }) do
    {:error, reason}
  end

  # @spec ORD-API-001
  def place_limit(cache_pid, coin, is_buy, limit_px, sz, opts) do
    with {:ok, %{asset_index: asset_index, size_decimals: size_decimals}} <-
           Ultramoist.AssetCache.lookup(cache_pid, coin) do
      formatted_price = format_price(limit_px, size_decimals)
      formatted_size = format_size(sz, size_decimals)
      action = build_place_action(asset_index, is_buy, formatted_price, formatted_size)

      with {:ok, response} <- sign_and_submit(action, opts) do
        parse_place_response(response)
      end
    end
  end

  def format_price(price, size_decimals) do
    decimal = to_decimal(price)

    if Decimal.integer?(decimal) do
      Decimal.to_string(decimal, :normal)
    else
      max_decimals = max(6 - size_decimals, 0)

      decimal
      |> Decimal.round(max_decimals, :down)
      |> round_significant(5)
      |> Decimal.normalize()
      |> Decimal.to_string(:normal)
    end
  end

  def format_size(size, size_decimals) do
    size
    |> to_decimal()
    |> Decimal.round(size_decimals, :down)
    |> Decimal.normalize()
    |> Decimal.to_string(:normal)
  end

  # @spec LEV-DATA-002
  def update_leverage(cache_pid, coin, opts) do
    with {:ok, %{asset_index: asset_index}} <- Ultramoist.AssetCache.lookup(cache_pid, coin) do
      action =
        build_update_leverage_action(
          asset_index: asset_index,
          is_cross: Keyword.fetch!(opts, :is_cross),
          leverage: Keyword.fetch!(opts, :leverage)
        )

      submit_opts = Keyword.drop(opts, [:is_cross, :leverage])

      with {:ok, response} <- sign_and_submit(action, submit_opts) do
        parse_update_leverage_response(response)
      end
    end
  end

  defp to_decimal(%Decimal{} = value), do: value
  defp to_decimal(value), do: Decimal.new(to_string(value))

  defp round_significant(decimal, significant_figures) do
    if Decimal.eq?(decimal, 0) do
      decimal
    else
      decimal_places = significant_figures - 1 - order_of_magnitude(decimal)
      Decimal.round(decimal, decimal_places, :down)
    end
  end

  defp order_of_magnitude(%Decimal{coef: coefficient, exp: exponent}) do
    digit_count = coefficient |> Integer.to_string() |> String.length()
    digit_count - 1 + exponent
  end

  # @spec ORD-API-003
  def cancel(opts) do
    asset_index = Keyword.fetch!(opts, :asset_index)
    order_id = Keyword.fetch!(opts, :order_id)
    action = build_cancel_action(asset_index, order_id)
    http_opts = Keyword.drop(opts, [:asset_index, :order_id])

    with {:ok, response} <- sign_and_submit(action, http_opts) do
      parse_cancel_response(response)
    end
  end

  defp sign_and_submit(action, opts) do
    priv_key = Keyword.fetch!(opts, :priv_key)
    source = Keyword.fetch!(opts, :source)
    vault_address = Keyword.get(opts, :vault_address)
    {http, http_opts} = Keyword.get(opts, :http, {Ultramoist.Http, []})

    next_nonce =
      Keyword.get(opts, :nonce, &Ultramoist.NonceAllocator.next_from_default_allocator/0)

    nonce = next_nonce.()

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

    agent_address = Ultramoist.Signer.agent_address(priv_key) |> Base.encode16(case: :lower)

    Logger.info(
      "Signing as agent 0x#{agent_address}, nonce #{nonce}, r=#{signature["r"]}, s=#{signature["s"]}, v=#{recovery_v}"
    )

    request_opts =
      opts
      |> Keyword.drop([:priv_key, :source, :vault_address, :http, :nonce])
      |> Keyword.merge(http_opts)
      |> Keyword.merge(signature: signature, nonce: nonce, vault_address: vault_address)

    http.exchange_request(action, request_opts)
  end
end
