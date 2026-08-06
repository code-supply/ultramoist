defmodule Ultramoist.Signer do
  @moduledoc false

  alias Ultramoist.Eip712
  alias Ultramoist.Keccak
  alias Ultramoist.Msgpack
  alias Ultramoist.Secp256k1

  def mainnet_source, do: "a"
  def testnet_source, do: "b"

  def sign_l1_action(action, opts) do
    nonce = Keyword.fetch!(opts, :nonce)
    source = Keyword.fetch!(opts, :source)
    priv_key = Keyword.fetch!(opts, :priv_key)
    vault_address = Keyword.get(opts, :vault_address)

    vault_bytes = if vault_address, do: <<1>> <> vault_address, else: <<0>>

    connection_id =
      Keccak.hash256(Msgpack.encode(action) <> <<nonce::64>> <> vault_bytes)

    struct_hash = Eip712.agent_struct_hash(source, connection_id)
    digest = Eip712.signing_digest(Eip712.domain_separator(), struct_hash)

    {signature_r, raw_s} = Secp256k1.sign(priv_key, digest)
    signature_s = Secp256k1.normalize_s(raw_s)

    {pub_key, _priv} = :crypto.generate_key(:ecdh, :secp256k1, priv_key)
    <<4, pub_x::256, pub_y::256>> = pub_key

    recovery_v = Secp256k1.recovery_id(signature_r, signature_s, digest, {pub_x, pub_y}) + 27

    {signature_r, signature_s, recovery_v}
  end
end
