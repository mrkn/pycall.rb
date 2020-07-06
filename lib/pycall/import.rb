require 'pycall'

if RUBY_ENGINE == "truffleruby"
  require 'pycall/truffleruby/import'
else
  require 'pycall/truffleruby/import_pycall'
end
