
describe Client do
  UMI::session_log_path = "./umisession.log"

  before :all do
    @test_access_key = begin
      PrivateKey.from_packed open(File.expand_path "~/.universa/test_access.private.unikey", 'rb').read
    rescue
      skip "no test key found: #$!"
    end
    @contract = nil
    @client = Client.new private_key: @test_access_key
  end


  it "scans the network" do
    @client.size.should > 10
    @client.should be_a_kind_of(Client)
    rc = @client.random_connection
    rc.should be_a_kind_of(Connection)
    rc.ping.should be_truthy
    rc.url.should =~ /http/
    # there is no more node 31
    expect(->{rc.ping_node 31}).to raise_error(Farcall::RemoteError)
  end

  it "ping nodes" do
    rc1, rc2 = @client.random_connections(2)
    # puts "ping #{rc1.node_number} -> #{rc2.node_number}"
    res = rc1.ping_node(rc2.node_number)
    res.UDP.should >= 0
    res.TCP.should >= 0
    # p res
    # p res.TCP
    # p res.UDP
  end

  context "with direct access" do
    it "checks single state on undefined" do
      # @client.random_connection.execute("sping").sping.should == 'spong'
      contract = Contract.create @test_access_key
      contract.definition.name = "just a test"
      contract.expires_at = Time.now + 900
      contract.seal()

      state = @client.random_connection.get_state contract
      state.state.should == 'UNDEFINED'
      state.is_pending.should == false
      state.is_approved.should == false
    end

    it "checks consensus state on undefined" do
      # @client.random_connection.execute("sping").sping.should == 'spong'
      contract = Contract.create @test_access_key
      contract.definition.name = "just a test"
      contract.expires_at = Time.now + 900
      contract.seal()

      state = @client.get_state contract, trust: 0.2
      state.state.should == 'UNDEFINED'
      state.is_pending.should == false
      state.is_approved.should == false
    end

    it "registers new contract and revokes it" do
      contract = Contract.create @test_access_key
      contract.definition.name = "just a test"
      contract.expires_at = Time.now + 900
      puts contract.expires_at
      contract.seal()

      state = @client.register_single contract
      state.should be_approved
      state.errors.should be_empty
      state.errors?.should be_falsey
      @client.get_state(contract).should be_approved
      @client.is_approved?(contract).should be_truthy
      @client.is_approved?(contract.hash_id).should be_truthy
      @client.is_approved?(contract.hash_id.to_s).should be_truthy
      @client.is_approved?(contract.hash_id.bytes).should be_truthy

      rev = contract.createRevocation(@test_access_key)
      state = @client.register_single(rev)
      state.should be_approved

      state = @client.get_state(contract)
      state.should_not be_approved
      @client.is_approved?(contract).should_not be_truthy
      state.state.should == 'REVOKED'
    end
  end
end