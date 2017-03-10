$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "pycall"

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
end
