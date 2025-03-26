defmodule Base64 do
  # tuple provides O(1) access
  @base64_charset "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  @base64_table @base64_charset
                |> :binary.bin_to_list()
                # |> Enum.map(fn <<x>> -> x end)
                |> List.to_tuple()

  # todo?
  # read how binary are implented in erlang
  # maybe make functions
  # since map with greater than 32 elements is not that efficient in erlang?
  # try benchmarking
  @base64_rev_table @base64_charset
                    |> String.graphemes()
                    |> Enum.with_index()
                    |> Map.new()

  # A bitstring having total number of bits equal to multiple of 8 is bianry.
  def encode(input, opts \\ []) when is_binary(input) do
    padding? = Keyword.get(opts, :padding, true)
    do_encode(input, <<>>, padding?)
  end

  # works by converting each 3 bytes(24 bits) into 4 sextets(24 bits)
  # we try to match first 24 bits
  # if there are less than 24 bits we need to do padding
  # if last block is of 2 byte(16 bits), make it 18 bits by appending 2 0's at LSB
  # encode 18 bits to 3 sextets, and append `=` as padding
  # if last block is of 1 byte(8 bits), make it 12 bits by appending 4 0's at LSB
  # encode 12 bits to 2 sextets, and append `==` as padding

  defp do_encode(<<>>, result, _padding?), do: result

  defp do_encode(<<block::binary-size(1)>>, result, padding?) do
    <<a::6, b::6>> = <<block::bitstring, 0::4>>
    pad = if padding?, do: "==", else: ""
    encoded_block = <<sextet_to_base64(a), sextet_to_base64(b)>> <> pad

    result <> encoded_block
  end

  defp do_encode(<<block::binary-size(2)>>, result, padding?) do
    <<a::6, b::6, c::6>> = <<block::bitstring, 0::2>>
    pad = if padding?, do: "=", else: ""
    encoded_block = <<sextet_to_base64(a), sextet_to_base64(b), sextet_to_base64(c)>> <> pad
    result <> encoded_block
  end

  defp do_encode(<<block::binary-size(3), rest::binary>>, result, padding?) do
    encoded_block = encode_block(block)
    do_encode(rest, result <> encoded_block, padding?)
  end

  defp encode_block(<<block::binary-size(3)>>) do
    <<a::6, b::6, c::6, d::6>> = block
    <<sextet_to_base64(a), sextet_to_base64(b), sextet_to_base64(c), sextet_to_base64(d)>>
  end

  defp sextet_to_base64(a) do
    elem(@base64_table, a)
  end

  # decode
  # convert four byte to 3 byte
  # todo: handle padding in decoding

  def decode(input, opts \\ []) do
    padding? = Keyword.get(opts, :padding, true)
    do_decode(input, <<>>, padding?)
  end

  defp do_decode(<<>>, result, padding?), do: result

  # will decode to 1 byte (12 -> 8 bits)
  defp do_decode(<<a::binary-size(1), b::binary-size(1), "==">>, result, padding?) do
    a = base64_to_sextet(a)
    b = base64_to_sextet(b)

    if a && b do
      <<decoded_block::binary-size(1), _::4>> = <<a::6, b::6>>
      result <> decoded_block
    else
      {:error, :invalid_base64_encoding}
    end
  end

  # will decode to 2 bytes (18 -> 16 bits)
  defp do_decode(
         <<a::binary-size(1), b::binary-size(1), c::binary-size(1), "=">>,
         result,
         padding?
       ) do
    a = base64_to_sextet(a)
    b = base64_to_sextet(b)
    c = base64_to_sextet(c)

    if a && b && c do
      <<decoded_block::binary-size(2), _::2>> = <<a::6, b::6, c::6>>
      result <> decoded_block
    else
      {:error, :invalid_base64_encoding}
    end
  end

  # todo handle whitespace and write test
  defp do_decode(<<block::binary-size(4), rest::binary>>, result, padding?) do
    # each bitstring is 1 byte by default
    <<a::binary-size(1), b::binary-size(1), c::binary-size(1), d::binary-size(1)>> = block

    a = base64_to_sextet(a)
    b = base64_to_sextet(b)
    c = base64_to_sextet(c)
    d = base64_to_sextet(d)

    if a && b && c && d do
      decoded_block = <<a::6, b::6, c::6, d::6>>
      do_decode(rest, result <> decoded_block, padding?)
    else
      {:error, :invalid_base64_encoding}
    end
  end

  defp base64_to_sextet(a) do
    Map.get(@base64_rev_table, a)
  end
end
