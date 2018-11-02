using Universa

describe "StringUtils" do
  it "converts snake to camel lower" do
    "foo_bar".camelize_lower.should == "fooBar"
    "foobar".camelize_lower.should == "foobar"
    "foo___bar".camelize_lower.should == "fooBar"
    "_foo___bar".camelize_lower.should == "fooBar"
    "_foOo___bar".camelize_lower.should == "foOoBar"
  end
end