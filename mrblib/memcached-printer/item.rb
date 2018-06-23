module MemcachedPrinter
  Item = ::Struct.new(:id, :key, :bytes, :expiration_time, :flags, :value) do
    def simple_format
      str = "#{id} #{key} #{bytes} #{expiration_time}"
      str = "#{str} #{flags} #{[value].pack('m0')}" if value
      str
    end

    def pretty_format
      str = "slab_id:#{id} key:#{key} size:#{bytes}bytes"
      str += if expiration_time == '0'
              " expiration_time:none"
            else
              " expiration_time:#{Time.at(expiration_time.to_i).strftime('%Y-%m-%d %H:%M:%S')}"
            end
      str += " flags:#{flags} base64_value:#{[value].pack('m0')}" if value
      str
    end
  end
end
