describe Contract do

  before :all do
    @private_key = PrivateKey.new 2048
  end

  it "creates contract with creator address" do
    c = Contract.create @private_key
    c.get_creator.get_all_addresses.should == [@private_key.long_address.to_s]
    c.seal()
    c.check() and c.trace_errors()
    c.should be_ok

    c1 = Contract.from_packed(c.packed)
    c1.hash_id.should == c.hash_id
    c1.expires_at.should > (Time.now + 120)
  end

  it "provides definition" do
    c = Contract.create @private_key
    c.definition[:name] = "test name"
    c.definition[:description] = "test description"
    c.seal()
    c.check() and c.trace_errors()
    c.should be_ok

    c1 = Contract.from_packed(c.packed)
    c1.hash_id.should == c.hash_id
    c1.definition[:name].should == "test name"
    c1.definition[:description].should == "test description"
  end

end