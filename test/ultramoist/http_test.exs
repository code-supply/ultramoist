defmodule Ultramoist.HttpTest do
  use ExUnit.Case, async: true

  # @spec HTTP-API-001
  test "makes a generic info request against the real testnet host" do
    assert {:ok, %{"universe" => [%{"name" => _name} | _rest]}} =
             Ultramoist.Http.info_request(%{"type" => "meta"},
               base_url: Ultramoist.Config.info_url(:testnet)
             )
  end

  # @spec TELEM-API-001
  test "emits telemetry for an info request, naming its type and base url" do
    ref =
      :telemetry_test.attach_event_handlers(self(), [[:ultramoist, :http, :info_request, :stop]])

    on_exit(fn -> :telemetry.detach(ref) end)

    base_url = Ultramoist.Config.info_url(:testnet)

    assert {:ok, _body} = Ultramoist.Http.info_request(%{"type" => "meta"}, base_url: base_url)

    assert_receive {[:ultramoist, :http, :info_request, :stop], ^ref, measurements, metadata}
    assert metadata.base_url == base_url
    assert metadata.type == "meta"
    assert is_integer(measurements.duration)
  end

  # @spec HTTP-API-003
  test "makes a stats request against the real testnet host" do
    assert {:ok, [%{"summary" => %{"vaultAddress" => _address}} | _rest]} =
             Ultramoist.Http.stats_request("vaults",
               base_url: Ultramoist.Config.stats_url(:testnet)
             )
  end

  # @spec TELEM-API-003
  test "emits telemetry for a stats request, naming its type and base url" do
    ref =
      :telemetry_test.attach_event_handlers(self(), [[:ultramoist, :http, :stats_request, :stop]])

    on_exit(fn -> :telemetry.detach(ref) end)

    base_url = Ultramoist.Config.stats_url(:testnet)

    assert {:ok, _body} = Ultramoist.Http.stats_request("vaults", base_url: base_url)

    assert_receive {[:ultramoist, :http, :stats_request, :stop], ^ref, measurements, metadata}
    assert metadata.base_url == base_url
    assert metadata.type == "vaults"
    assert is_integer(measurements.duration)
  end

  # @spec TELEM-API-005
  test "emits telemetry for an exchange request, naming its action type and base url" do
    ref =
      :telemetry_test.attach_event_handlers(self(), [
        [:ultramoist, :http, :exchange_request, :stop]
      ])

    on_exit(fn -> :telemetry.detach(ref) end)

    action = %{"type" => "cancel", "cancels" => []}

    signature = %{
      "r" => "0x" <> String.duplicate("1", 64),
      "s" => "0x" <> String.duplicate("2", 64),
      "v" => 27
    }

    base_url = Ultramoist.Config.info_url(:testnet)

    assert {:ok, _body} =
             Ultramoist.Http.exchange_request(action,
               signature: signature,
               nonce: 1,
               vault_address: nil,
               base_url: base_url
             )

    assert_receive {[:ultramoist, :http, :exchange_request, :stop], ^ref, measurements, metadata}
    assert metadata.base_url == base_url
    assert metadata.type == "cancel"
    assert is_integer(measurements.duration)
  end

  # @spec HTTP-API-002
  test "makes a signed exchange-action request against the real testnet host" do
    action = %{"type" => "cancel", "cancels" => []}

    signature = %{
      "r" => "0x" <> String.duplicate("1", 64),
      "s" => "0x" <> String.duplicate("2", 64),
      "v" => 27
    }

    assert {:ok, %{"status" => "err"}} =
             Ultramoist.Http.exchange_request(action,
               signature: signature,
               nonce: 1,
               vault_address: nil,
               base_url: Ultramoist.Config.info_url(:testnet)
             )
  end

  # @spec HTTP-API-004
  test "returns an error instead of a bare body when the exchange rejects the request outright" do
    action = %{"type" => "cancel", "cancels" => []}

    signature = %{
      "r" => "0x" <> String.duplicate("1", 64),
      "s" => "0x" <> String.duplicate("2", 64),
      "v" => 27
    }

    assert {:error, {422, "Failed to deserialize the JSON body into the target type"}} =
             Ultramoist.Http.exchange_request(action,
               signature: signature,
               nonce: "not-a-number",
               vault_address: nil,
               base_url: Ultramoist.Config.info_url(:testnet)
             )
  end
end
