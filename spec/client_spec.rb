
describe Client do
  before :all do
    @client = Client.new
  end


  it "scans the network" do
    client = Client.new
    client.size.should > 30
    client.random_connection.ping.sping.should == 'spong'
    client.random_connection.execute("sping").sping.should == 'spong'
  end

  context "with access" do
    before :all do
      @test_access_key = begin
        PrivateKey.from_packed open(File.expand_path "~/.universa/test_access.private.unikey", 'rb').read
      rescue
        skip "no test key found: #$!"
      end
      @client = Client.new @test_access_key
    end

    it "registers and checks state" do
      # @client.random_connection.execute("sping").sping.should == 'spong'
      contract = Contract.create @test_access_key
      contract.definition[:name] = "just a test"
      contract.expires_at = Time.now + 900
      contract.seal()

      state = @client.get_state contract
      state.state.should == 'UNDEFINED'
      state.is_pending.should == false
      state.is_approved.should == false

      state = @client.register_single contract
      state.should be_approved
      state.errors.should be_nil
      @client.get_state(contract).should be_approved

      # contract = contract.create_revocation(@test_access_key)
      # p contract
      # state = @client.register_single(contract)
      # state.should_not be_approved
      # state.state.should == 'REVOKED'
    end

  end

  # it "registers contracts" do
  # end
end