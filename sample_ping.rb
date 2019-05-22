# for admin keys, how to check network inner visiblity
#
require 'universa'

include Universa

# the key with administrative access to the network in question
access_key = PrivateKey.from_packed open(File.expand_path "~/.universa/test_access.private.unikey", 'rb').read

# set the topology to the network you need
client = client = Client.new topology: 'mainnet', private_key: access_key

node1, node2 = client.random_connections(2)
puts "Checking ping #{node1.node_number} -> #{node2.node_number}"

result = node1.ping_node(node2.node_number)
puts "TCP=#{result.TCP}ms, UDP=#{result.UDP}ms"
