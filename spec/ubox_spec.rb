# # THIS IS A WORK IN PROGRESS COULD VE CHANGED COMPLETELY, OR EVEN DROPPED. DO NOT USE!
# describe UBox do
#   before :all do
#     @test_access_key = begin
#       PrivateKey.from_packed open(File.expand_path "~/.universa/test_access.private.unikey", 'rb').read
#     rescue
#       skip "no test key found: #$!"
#     end
#     @client = Client.new private_key: @test_access_key
#   end
#
#   it "imports contract" do
#     UBox.im
#   end
#
# end