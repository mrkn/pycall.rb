$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

puts
if RUBY_ENGINE != "truffleruby"
  puts "Environment variables:"
  %w[
    ANACONDA
    LIBPYTHON
    PYENV_VERSION
    PYTHON
    PYTHON_VERSION
    PYTHONPATH
    PYCALL_DEBUG_FIND_LIBPYTHON
].each do |key|
    puts "- #{key}=#{ENV[key]}"
  end
end

require 'pycall'

puts
puts "The following version of Python is used:"
puts PyCall::PYTHON_DESCRIPTION

require 'pycall/import'
if RUBY_ENGINE != "truffleruby"
  require 'pycall/spec_helper.so'
  require "pycall/pretty_print"
end

PyCall.sys.path.append(File.expand_path('../python', __FILE__))

Dir.glob(File.expand_path('../support/**/*.rb', __FILE__)) do |file|
  require file
end

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expose_current_running_example_as :example
  config.filter_run_when_matching :focus
  config.order = :random
  config.seed = ENV['RSPEC_SEED'] if ENV['RSPEC_SEED']
  config.profile_examples = true if ENV['RSPEC_PROFILING']

  config.after do
    if PyCall::PyError.occurred?
      pyerr = PyCall::PyError.fetch
      raise "unhandled python exception: #{pyerr}" if pyerr
    end
  end
end
