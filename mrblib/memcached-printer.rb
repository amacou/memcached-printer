def __main__(argv)
  options = { host: 'localhost', port: 11211, base64: false }

  op = OptionParser.new do |opts|
    opts.banner = "Usage: memcached-printer [options]"

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
    opts.on("-v", "--with-value", "print raw value") do |v|
      options[:show_value] = v
    end
    opts.on("-b", "--base64", "value to encode by base64") do |v|
      options[:base64] = true
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
      item.value, item.flags = client.fetch_value_and_flags(item.key) if options[:show_value]

      if options[:pretty_print]
        puts item.pretty_format(options[:base64])
      else
        puts item.simple_format(options[:base64])
      end
    end
  end

  client.close
end
