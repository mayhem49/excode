defmodule Base64Test do
  use ExUnit.Case

  @invalid_base64_strings [
    "==ab",
    "=abc",
    # Contains invalid special characters
    "abc$%^",
    # completely invalid
    "!!!!!",
    # Space inside a Base64 string
    "ABCD EFGH",
    # Invalid character '@' in encoded string
    "aGVsbG8@",
    # Triple padding, which is invalid
    "YQ==="
  ]
  @strings_to_check [
    # long string
    "adfjlasjfl;asjfkjaskdfljasjjfasdlf;kas",
    # perfectly aligned string (6 characters)
    "ABCDEF",
    # last block with 2 characters (padding needed)
    "ABCDE",
    # last block with 3 characters (no padding)
    "ABCD",
    # 3 characters (no padding)
    "ABC",
    # 2 characters (padding needed)
    "AB",
    # 1 character (padding needed)
    "A",
    # 0 characters (empty string)
    "",
    # 5 characters (padding needed)
    "Hello",
    # 6 characters (no padding)
    "OpenAI",
    # 6 characters (no padding)
    "Elixir",
    # 3 characters (no padding)
    "123",
    # 5 characters (padding needed)
    "12345",
    # 7 characters (padding needed)
    "abcdefg",
    # 1 character (padding needed)
    "X",
    # 8 characters (no padding)
    "12345678",
    "&(*)&%^)(@&$*",
    "   "
  ]

  test "performs encoding" do
    strings_to_check = @strings_to_check

    Enum.each(strings_to_check, fn str ->
      assert Base.encode64(str) == Base64.encode(str)
    end)
  end

  test "performs encoding without padding" do
    strings_to_check = @strings_to_check

    Enum.each(strings_to_check, fn str ->
      assert Base.encode64(str, padding: false) == Base64.encode(str, padding: false)
    end)
  end

  test "performs decoding with padded base64" do
    str = "abcdef"
    encoded_str = Base64.encode(str, padding: true) |> IO.inspect(label: :encoded)
    assert str == Base64.decode(encoded_str, padding: true) |> IO.inspect(label: :decoded)

    strings_to_check = @strings_to_check

    Enum.each(strings_to_check, fn str ->
      encoded_str = Base64.encode(str, padding: true)
      assert str == Base64.decode(encoded_str, padding: true)
    end)
  end

  test "performs decoding of base64 string without padding" do
    str = "abcdef"
    encoded_str = Base64.encode(str, padding: false) |> IO.inspect(label: :encoded)
    assert str == Base64.decode(encoded_str, padding: false) |> IO.inspect(label: :decoded)

    strings_to_check = @strings_to_check

    Enum.each(strings_to_check, fn str ->
      # just fun
      encoder_fun = Enum.random([&Base.encode64/2, &Base64.encode/2])
      encoded_str = encoder_fun.(str, padding: false)
      assert str == Base64.decode(encoded_str, padding: false)
    end)
  end

  test "returns error when invalid base64 string is provided to decode" do
    Enum.each(@invalid_base64_strings, fn invalid_str ->
      assert {:error, _} = Base64.decode(invalid_str)
    end)
  end
end
