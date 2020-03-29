# example:
#
# rationale:
# We want to pass order code to user which is potentially long integer (sam, above 9 characters in decimal
# notation), but the bank insist oreder code in the payment purpose should be 5-8 characters.
#
# solution:
#
# pack long id (we assume it will fit 5 bytes that give us >60 billions which is usually more
# than enough) to short and easy to human-retype code using SAFE58 encoding by Universa.
#
# It will nirmally give us 6 letter-code which is well protected against recognition mistakes,
# for example 0 instead of o or 1 instead of I or i. It autocorrects it and does not use like characters.
#
require 'universa'

# sample long to encode, 12 billions+ (12`884`901`887)
id = 0x2FFFFffff

def int_to_safe58(value)
    # pack to BE 8-byte long
    packed = [value].pack("Q>")

    # important: safe58 needs binary encoded string, but pack already gives us binary string,
    # so we strip 3 first bytes which are are zeroes and encode the rest to safe 58:
    Universa::Safe58.encode(packed[3..])
end

def safe58_to_int(encoded)
    # decode 5 bytes
    bytes = Universa::Safe58.decode(encoded)
    # pad left with 3 zero bytes to get back 64 bit integer and unpack it:
    "\x0\x0\x0#{bytes}".unpack("Q>")[0]
end

puts "Encoded: #{id} -> #{int_to_safe58 id}"

id2 = safe58_to_int(int_to_safe58(id))
puts "Decoded: #{int_to_safe58 id} -> #{id2}"

id == id2 or raise "test failed"

puts "ALL OK"


