defmodule HabitatMatch.DocumentCrypto do
  @aad "habitatmatch-document-v1"
  def encrypt(plaintext) do
    key = key!(); iv = :crypto.strong_rand_bytes(12)
    {ciphertext, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, @aad, true)
    <<iv::binary-size(12), tag::binary-size(16), ciphertext::binary>>
  end
  def decrypt(<<iv::binary-size(12), tag::binary-size(16), ciphertext::binary>>) do
    :crypto.crypto_one_time_aead(:aes_256_gcm, key!(), iv, ciphertext, @aad, tag)
  end
  defp key! do
    case System.fetch_env("DOCUMENT_ENCRYPTION_KEY") do
      {:ok, value} -> case Base.decode64(value) do {:ok, <<key::binary-size(32)>>} -> key; _ -> raise "DOCUMENT_ENCRYPTION_KEY must be base64 for exactly 32 bytes" end
      :error -> raise "DOCUMENT_ENCRYPTION_KEY is required"
    end
  end
end
