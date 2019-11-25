
describe KeyAddress do

  before :all do
    @key = PrivateKey.new 2048
  end

  it "converts to and from string/binary rep" do
    key = @key
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
  end

  it "packs with password not touching the address" do
    k1 = PrivateKey.from_packed(@key.pack_with_password("helloworld"), password: "helloworld")
    k1.should == @key
    k1.short_address.to_s.should == @key.short_address.to_s
  end

  it "properly raises exception on unknown method" do
    x = KeyAddress.new("JayLwvgbmxnhVDRx19U85eDJxPHfLPiNTqxMQDGSL6x2aPi3NDgWHNaq6uB6K7Gr6GSUjKTZ")
    expect(->{x.not_existing_method(1)}).to raise_error(NoMethodError)
  end

  it "convertis to binder" do
    x = Binder.of hello: "world", 1 => 3
    x["hello"].should == "world"
    x[:hello].should == "world"
    x["1"].should == 3
  end

  it "properly compares and uses as a key" do
    a1 = @key.short_address
    a2 = KeyAddress.new(a1.packed)
    a1.should == a2
    a1.eql?(a2).should be_truthy
    a2.eql?(a1).should be_truthy
    map = {}
    map[a1] = 'a1'
    map[a1].should == 'a1'
    map[a2].should == 'a1'
    map.should include(a1)
    map.should include(a2)
  end

end