
describe KeyAddress do

  it "converts to and from string/binary rep" do
    key = PrivateKey.new 2048
    sa = key.short_address
    la = key.long_address

    sa.to_s.size.should <= 51
    sa.to_s.size.should >= 50

    sa.packed.size.should == 37

    la.to_s.size.should <= 72 # not sure
    la.to_s.size.should >= 71 # not sure

    la.packed.size.should == 53

    KeyAddress.from_packed(la.packed).should == la
    KeyAddress.from_packed(sa.packed).should == sa

    KeyAddress.new(sa.to_s).should == sa
    KeyAddress.new(la.to_s).should == la

    p la.to_s
  end

  it "properly raises exception on unknown method" do
    x = KeyAddress.new("JayLwvgbmxnhVDRx19U85eDJxPHfLPiNTqxMQDGSL6x2aPi3NDgWHNaq6uB6K7Gr6GSUjKTZ")
    expect(->{x.not_existing_method(1)}).to raise_error(NoMethodError)
  end

end