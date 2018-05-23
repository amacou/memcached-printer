MRuby::Gem::Specification.new('memcached-printer') do |spec|
  spec.license = 'MIT'
  spec.author  = 'MRuby Developer'
  spec.summary = 'memcached-printer'
  spec.bins    = ['memcached-printer']

  spec.add_dependency 'mruby-print', core:'mruby-print'
  spec.add_dependency 'mruby-hash-ext', core: 'mruby-hash-ext'
  spec.add_dependency 'mruby-struct', core: 'mruby-struct'
  spec.add_dependency 'mruby-onig-regexp', mgem: 'mruby-onig-regexp'
  spec.add_dependency 'mruby-socket', mgem: 'mruby-socket'
  spec.add_dependency 'mruby-mtest', mgem:'mruby-mtest'
  spec.add_dependency 'mruby-optparse', mgem: 'mruby-optparse'
  spec.add_dependency 'mruby-time-strftime', mgem:'mruby-time-strftime'
end
