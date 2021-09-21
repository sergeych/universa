module Universa

  # Convert binary data to a human-readable dump string, like
  #
  # <code>
  # 000000 27 23 64 61 74 61 c4 2d 0f |'#data.-.|
  # 000008 0f 1f 43 63 6f 6e 74 72 61 |..Ccontra|
  # </code>
  #
  # @param data[String] data to dump
  # @param line_bytes[Number] how many bytes to show in each line
  # @return [String] dump as a string
  def dump_bytes data, line_bytes=16
    data.force_encoding Encoding::BINARY
    offset = 0
    res = []

    while( offset < data.length )

      left = "%06x" % offset
      portion = data[offset..(offset+line_bytes)].bytes

      bytes = portion.map { |x| "%02x" % x }.join(' ')
      chars = portion.map { |c| x = c.ord; x >= 32 && x <= 'z'.ord ? x.chr : '.' }.join('')

      if chars.length < line_bytes
        pad = line_bytes - chars.length + 1
        chars += ' ' * pad
        bytes += '   ' * pad
      end

      res << "#{left} #{bytes} |#{chars}|"

      offset += line_bytes
    end
    res.join("\n")
  end

  module_function :dump_bytes
end