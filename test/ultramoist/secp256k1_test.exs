defmodule Ultramoist.Secp256k1Test do
  use ExUnit.Case, async: true

  @curve_order 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141

  @priv_key :crypto.hash(:sha256, "private key")
  @digest Ultramoist.Keccak.hash256("test")

  # @spec SIGN-DATA-001
  test "signs a digest and the signature verifies against the public key" do
    {r, s} = Ultramoist.Secp256k1.sign(@priv_key, @digest)

    der =
      :public_key.der_encode(
        :"ECDSA-Sig-Value",
        {:"ECDSA-Sig-Value", :binary.decode_unsigned(r), :binary.decode_unsigned(s)}
      )

    {pub_key, _priv} = :crypto.generate_key(:ecdh, :secp256k1, @priv_key)

    assert :crypto.verify(:ecdsa, :sha256, {:digest, @digest}, der, [pub_key, :secp256k1])
  end

  # @spec SIGN-DATA-002
  test "normalizes a high s value to curve_order - s" do
    high_s = <<@curve_order - 1::256>>
    assert Ultramoist.Secp256k1.normalize_s(high_s) == <<1::256>>
  end

  # @spec SIGN-DATA-002a
  test "leaves an already-low s value unchanged" do
    low_s = <<1::256>>
    assert Ultramoist.Secp256k1.normalize_s(low_s) == low_s
  end
end
