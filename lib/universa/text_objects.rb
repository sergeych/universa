require 'digest'

# Generate universa text object representation from arbitrary data, see
# https://kb.universablockchain.com/text_format_for_universa_objects/311
# for details.
#
# @param [Object] data binary string to pack as universa text object
# @param [Object] type object type, see link above
# @param [Hash] kwargs any additional fields
# @return [String] string with properly framed universa object
def format_text_object(data, type, **kwargs)
  source = ["type: #{type}"]
  kwargs.each { |k, v|
    source << "#{k}: #{v}"
  }
  source << ""
  source << Base64.encode64(data)
  hash = Digest::SHA2.base64digest(source.join(''))
  "==== Begin Universa Object: #{hash} ====\n" +
    source.join("\n") +
    "\n===== End Universa Object: #{hash} =====\n"
end