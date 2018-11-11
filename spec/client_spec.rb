
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
end