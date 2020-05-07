# Building with TruffleRuby does not work / is not required
# Seems like putting out an empty Makefile is the best solution to skip build
# https://stackoverflow.com/questions/17406246/native-extensions-fallback-to-pure-ruby-if-not-supported-on-gem-install/50886432

if RUBY_ENGINE == "truffleruby"
  mfile = open("Makefile", "wb")
  mfile.puts '.PHONY: install'
  mfile.puts 'install:'
  mfile.puts "\t" + '@echo "You are using Truffleruby, therefore skipping build of native extension"'
  mfile.close
  exit 0
end

require 'mkmf'

create_makefile('pycall')
