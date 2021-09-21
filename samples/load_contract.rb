require_relative '../lib/universa/dump'

source_file = ARGV[0] || File.expand_path("~/Downloads/c.unicon")

packed = open(source_file,'rb') { |f| f.read }

puts Universa::dump_bytes(packed)

require 'base64'
puts Base64.encode64(packed)
