using Universa



describe "StringUtils" do
  it "converts snake to camel lower" do
    "foo_bar".camelize_lower.should == "fooBar"
    "foobar".camelize_lower.should == "foobar"
    "foo___bar".camelize_lower.should == "fooBar"
    "_foo___bar".camelize_lower.should == "fooBar"
    "_foOo___bar".camelize_lower.should == "foOoBar"
    "toBase64String".camelize_lower.should == "toBase64String"
    "to_base64_string".camelize_lower.should == "toBase64String"
  end

  # it "performs safe58" do
  #   source = "123456"
  #   source.force_encoding('binary')
  #   x = Safe58.encode(source)
  #   p x
  #   Safe58.decode(x).should == source
  #
  #
  #   # ID:
  #
  #   x = Safe32.encode(source)
  #   p x
  #   p Safe32.decode(x)
  #
  #   # id: 5 bytes, CRC 1 byte = 6 bytes
  #
  #   p (0x7fFfFfFf * 256 / 1000000000.0)
  # end
end