defmodule Ultramoist.SignerTest do
  use ExUnit.Case, async: true

  @priv_key :crypto.hash(:sha256, "private key")

  # @spec L1S-DATA-001
  test "signs an L1 action, verifiable against the public key" do
    action = [type: "cancel"]
    nonce = 1_700_000_000_000

    {signature_r, signature_s, recovery_v} =
      Ultramoist.Signer.sign_l1_action(action,
        nonce: nonce,
        source: Ultramoist.Signer.mainnet_source(),
        priv_key: @priv_key
      )

    assert recovery_v in [27, 28]

    der =
      :public_key.der_encode(
        :"ECDSA-Sig-Value",
        {:"ECDSA-Sig-Value", :binary.decode_unsigned(signature_r),
         :binary.decode_unsigned(signature_s)}
      )

    {pub_key, _priv} = :crypto.generate_key(:ecdh, :secp256k1, @priv_key)

    connection_id =
      Ultramoist.Keccak.hash256(Ultramoist.Msgpack.encode(action) <> <<nonce::64>> <> <<0>>)

    struct_hash =
      Ultramoist.Eip712.agent_struct_hash(Ultramoist.Signer.mainnet_source(), connection_id)

    digest = Ultramoist.Eip712.signing_digest(Ultramoist.Eip712.domain_separator(), struct_hash)

    assert :crypto.verify(:ecdsa, :sha256, {:digest, digest}, der, [pub_key, :secp256k1])
  end

  # @spec L1S-DATA-002
  test "signs with a vault address included in what gets signed" do
    action = [type: "cancel"]
    nonce = 1_700_000_000_000
    vault_address = :crypto.hash(:sha256, "vault") |> binary_part(0, 20)

    {signature_r, signature_s, _recovery_v} =
      Ultramoist.Signer.sign_l1_action(action,
        nonce: nonce,
        vault_address: vault_address,
        source: Ultramoist.Signer.mainnet_source(),
        priv_key: @priv_key
      )

    der =
      :public_key.der_encode(
        :"ECDSA-Sig-Value",
        {:"ECDSA-Sig-Value", :binary.decode_unsigned(signature_r),
         :binary.decode_unsigned(signature_s)}
      )

    {pub_key, _priv} = :crypto.generate_key(:ecdh, :secp256k1, @priv_key)

    connection_id =
      Ultramoist.Keccak.hash256(
        Ultramoist.Msgpack.encode(action) <> <<nonce::64>> <> <<1>> <> vault_address
      )

    struct_hash =
      Ultramoist.Eip712.agent_struct_hash(Ultramoist.Signer.mainnet_source(), connection_id)

    digest = Ultramoist.Eip712.signing_digest(Ultramoist.Eip712.domain_separator(), struct_hash)

    assert :crypto.verify(:ecdsa, :sha256, {:digest, digest}, der, [pub_key, :secp256k1])
  end

  # @spec L1S-DATA-003
  test "derives the Ethereum address that owns a given private key" do
    {pub_key, _priv} = :crypto.generate_key(:ecdh, :secp256k1, @priv_key)
    <<4, pub_x::256, pub_y::256>> = pub_key
    expected = Ultramoist.Keccak.hash256(<<pub_x::256, pub_y::256>>) |> binary_part(12, 20)

    assert Ultramoist.Signer.agent_address(@priv_key) == expected
  end
end
