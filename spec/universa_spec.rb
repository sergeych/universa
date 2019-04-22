RSpec.describe Universa do

  before :all do
    @umi = UMI.new
  rescue
    puts $!.backtrace.join("\n")
    raise
  end

  after :all do
    @umi.close()
  end

  it "has a version number" do
    expect(Universa::VERSION).not_to be nil
    (@umi.version =~ /^(\d+)\.(\d+\.\d+)$/).should be_truthy
    $2.to_f.should >= 8.24
  end

  it "provides references to universa library objects" do
    i = begin
      key = @umi.instantiate "PrivateKey", 2048
      contract = @umi.instantiate "Contract", key
      id = contract._remote_id
      k1 = contract.getKeysToSignWith()[0]
      k2 = contract.getKeysToSignWith()[0]
      k3 = contract.getKeysToSignWith()[0]
      address = contract.getKeysToSignWith()[0].getPublicKey().getShortAddress().toString()
      key.getPublicKey().getShortAddress().toString.should == address
      key.get_public_key.get_short_address.to_string.should == address
      k1.should == key
      k2.should == k1
      k3.should == key
      contract = key = k1 = k2 = k3 = nil
      id
    end
    ObjectSpace.garbage_collect(full_mark: true, immediate_sweep: true)
    @umi.find_by_remote_id(i).should be_nil
  end

  it "checks object equality" do
    # c1 = @umi.instantiate "Contract"
    # p c1.seal()
    key1 = @umi.instantiate( "PrivateKey", 2048)
    key2 = @umi.instantiate( "PrivateKey", key1.pack())
    key1._remote_id.should_not == key2._remote_id
    # @umi.with_trace {
    key1.should == key2
    key1.should_not === key2
    key1.should === key1
    # }
  end


end
