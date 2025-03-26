defmodule Base64Test do
  use ExUnit.Case

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

  test "performs decoding" do
    str = "abcdef"
    encoded_str = Base64.encode(str) |> IO.inspect(label: :encoded)
    assert str ==  Base64.decode(encoded_str) |> IO.inspect(label: :decoded)


    strings_to_check = @strings_to_check
    Enum.each(strings_to_check, fn str ->
    encoded_str = Base64.encode(str)
    assert str ==  Base64.decode(encoded_str) 
    end)
  end
end
