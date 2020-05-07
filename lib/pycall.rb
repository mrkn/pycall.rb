if RUBY_ENGINE == "truffleruby"
  require 'pycall/pycall_truffleruby'
else
  require 'pycall/pycall'
end