# Excode
Implementing encoding and decoding mechanism of various formats, primarily to gain experience with bitstrings & binaries in elixir.

# cmpleted
[x] base64

# TODO
[] handle whitespace


# base64
For base64 decoding, follwing cases are handled:
- returns error when the string contains more than necessary padding character(`=`). 
  Example: "darkab======" throws error
 
- return error when the bits that are set as 0 while encoding are replaced with non-zero bits
see [Base64 Malleability in Practice](https://eprint.iacr.org/2022/361.pdf) or test cases for details
> For instance, the following strings:
QzNWwQ== (010000 110011 001101 010110 110000 010000 in binary)
QzNWwc== (010000 110011 001101 010110 110000 011100 in binary)
will be successfully decoded to the same data if the last 4 zero padding bits check
gets omitted. Obviously, in the above example QzNWwc== is padded incorrectly
as the last 4 bits of the last 6 bit chunk should be zero



