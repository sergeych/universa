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
end