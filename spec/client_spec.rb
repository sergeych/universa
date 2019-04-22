describe Client do
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
      contract.seal()

      state = @client.register_single contract
      state.should be_approved
      state.errors.should be_empty
      state.errors?.should be_falsey
      @client.get_state(contract).should be_approved

      rev = contract.createRevocation(@test_access_key)
      state = @client.register_single(rev)
      state.should be_approved

      state = @client.get_state(contract)
      state.should_not be_approved
      state.state.should == 'REVOKED'
    end
  end
end