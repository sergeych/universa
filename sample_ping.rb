# for admin keys, how to check network inner visiblity
#
require 'universa'

include Universa

# the key with administrative access to the network in question
access_key = PrivateKey.from_packed open(File.expand_path "~/.universa/test_access.private.unikey", 'rb').read

# set the topology to the network you need
client = client = Client.new topology: 'mainnet', private_key: @test_access_key

node1, node2 = client.random_connections(2)
puts "Checking ping #{node1.node_number} -> #{node2.node_number}"
# client[0].ping_node(client)