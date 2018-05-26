def __main__(argv)
  options = { host: 'localhost', port: 11211 }

  op = OptionParser.new do |opts|
    opts.on("-v", "--version", "show version number") do |v|
      puts "v#{MemcachedPrinter::VERSION}"
      exit
    end
    opts.on("-h VAL", "--host=VAL", "memcached host. default #{options[:host]}") do |v|
      options[:host] = v
    end
    opts.on("-p VAL", "--port=VAL", "memcached port. default #{options[:port]}") do |v|
      options[:port] = v
    end
    opts.on("-i VAL", "--slab_id=VAL", "memcached slab id. default #{options[:slab_id]}") do |v|
      options[:slab_id] = v
    end
    opts.on("-v", "--with-value", "print base64 encoded value") do |v|
      options[:show_value] = v
    end
    opts.on("-L", "--with-label", "pretty print") do |v|
      options[:pretty_print] = v
    end
  end
  op.parse! argv

  client = MemcachedPrinter::Client.new(options[:host], options[:port])

  slab_id_and_limit_list = client.fetch_slab_id_and_limit_list

  if options[:slab_id]
    slab_id_and_limit_list = { options[:slab_id] => slab_id_and_limit_list[options[:slab_id]] }
  end

  slab_id_and_limit_list.each do |slab_id, limit|
    client.fetch_items_with_key(slab_id, limit).each do |item|
      item.value = client.fetch_value(item.key) if options[:show_value]

      if options[:pretty_print]
        puts item.pretty_format
      else
        puts item.simple_format
      end
    end
  end

  client.close
end

module MemcachedPrinter
  Item = ::Struct.new(:id, :key, :bytes, :expiration_time, :value) do
    def simple_format
      str = "#{id} #{key} #{bytes} #{expiration_time}"
      str = "#{str} #{[value].pack('m0')}" if value
      str
    end

    def pretty_format
      str = "slab_id:#{id} key:#{key} size:#{bytes}bytes"
      str += if expiration_time == '0'
              " expiration_time:none"
            else
              " expiration_time:#{Time.at(expiration_time.to_i).strftime('%Y-%m-%d %H:%M:%S')}"
            end
      str += " base64_value:#{[value].pack('m0')}" if value
      str
    end
  end

  class Client
    attr_reader :host, :port

    def initialize(host, port)
      @host = host
      @port = port
    end

    def fetch_slab_id_and_limit_list
      socket.write "stats items\r\n"
      stats = {}

      while line = socket.gets do
        if error_response? line
          puts line
          exit
        end

        break if line == "END\r\n"
        # STAT items:1:number 1
        if match = line.match(/\ASTAT items:(?<slab_id>\d+):number (?<limit>\d+)/)
          stats[match[:slab_id]] = match[:limit]
        end
      end
      stats
    end

    def fetch_items_with_key(slab_id, limit)
      items = []
      socket.write "stats cachedump #{slab_id} #{limit}\r\n"
      while line = socket.gets do
        if error_response? line
          puts line
          exit 1
        end

        break if line == "END\r\n"
        # ITEM hello [15 b; 0 s]
        if match = line.match(/\AITEM (?<key>\S+) \[(?<bytes>\d+) b; (?<expiration_time>\d+) s\]/)
          items << Item.new(slab_id, match[:key], match[:bytes], match[:expiration_time], nil)
        end
      end

      items
    end

    def fetch_value(key)
      socket.write "get #{key}\r\n"
      keyline = socket.gets # "VALUE <key> <flags> <bytes>\r\n"

      if keyline.nil?
        socket.close
        puts "lost connection to #{host}:#{port}"
        exit 1
      end

      if error_response? keyline
        socket.close
        puts response
        exit 1
      end

      return nil if keyline == "END\r\n"

      unless match = keyline.match(/(?<bytes>\d+)\r/)
        socket.close
        puts "unexpected response #{keyline.inspect}"
        exit 1
      end

      value = socket.read match[:bytes].to_i
      socket.read 2 # "\r\n"
      socket.gets   # "END\r\n"
      value
    end

    private
    def error_response?(response)
      response.match?(/\A(?:CLIENT_|SERVER_)?ERROR(.*)/)
    end

    def socket
      return @socket if @socket and not @socket.closed?

      begin
        @socket = TCPSocket.new(host, port)
        @socket.setsockopt Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1
      rescue SocketError, SystemCallError, IOError, Timeout::Error => e
        close
        raise "Unable to open socket: #{e.class.name}, #{e.message}"
      end

      @socket
    end

    def close
      @socket.close if @socket && !@socket.closed?
      @socket = nil
    end
  end
end
