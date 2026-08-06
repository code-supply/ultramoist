defmodule Ultramoist.Secp256k1 do
  @moduledoc false

  @curve_order 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141

  def sign(priv_key, digest) do
    der = :crypto.sign(:ecdsa, :sha256, {:digest, digest}, [priv_key, :secp256k1])
    {:"ECDSA-Sig-Value", r, s} = :public_key.der_decode(:"ECDSA-Sig-Value", der)
    {<<r::256>>, <<s::256>>}
  end

  def normalize_s(s) do
    s_int = :binary.decode_unsigned(s)

    if s_int > div(@curve_order, 2) do
      <<@curve_order - s_int::256>>
    else
      s
    end
  end
end
