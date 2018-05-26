# memcached-printer
command-line tool for print memcached key and value

## Compile

```sh
docker-compose run compile
#=> ./mruby/build/x86_64-apple-darwin14/bin/memcached-printer
```

## Usage

### print memcached keys
```sh
memcached-printer
#=> 1 hello 15 0
```

### host and port (detailt: localhost:11211)
```sh
memcached-printer -h 192.0.2.0 -p 12345
```


### with label
```sh
memcached-printer -L
#=> slab_id:1 key:hello size:15bytes expiration_time:none
```

### with value
```sh
memcached-printer -v
#=> 1 hello 15 0 BAhJIgp3b3JsZAY6BkVU

memcached-printer -vL
#=> slab_id:1 key:hello size:15bytes expiration_time:none base64_value:BAhJIgp3b3JsZAY6BkVU
```

### filter by slab_node
```sh
memcached-printer
1 hello 15 0
3 app_v1:abc 77 1527778801

memcached-printer -i 1
1 hello 15 0
```
