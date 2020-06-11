if RUBY_ENGINE == "truffleruby"
  require 'pycall/truffleruby/pycall'
else
  require 'pycall/pycall'
end