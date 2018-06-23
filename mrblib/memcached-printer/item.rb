module MemcachedPrinter
  Item = ::Struct.new(:id, :key, :bytes, :expiration_time, :flags, :value) do
    def simple_format(base64 = false)
      str = "#{id} #{key} #{bytes} #{expiration_time}"
      return str unless value

      str = if base64
              "#{str} #{flags} #{base64_value}"
            else
              "#{str} #{flags} #{value}"
            end
    end

    def pretty_format(base64 = false)
      str = "slab_id:#{id} key:#{key} size:#{bytes}bytes"
      str += if expiration_time == '0'
               " expiration_time:none"
             else
               " expiration_time:#{Time.at(expiration_time.to_i).strftime('%Y-%m-%d %H:%M:%S')}"
             end
      return str unless value

      str += if base64
               " flags:#{flags} base64_value:#{base64_value}"
             else
               " flags:#{flags} value:#{value}"
             end
    end

    def base64_value
      [value].pack('m0')
    end
  end
end
