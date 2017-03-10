$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "pycall"

Dir.glob(File.expand_path('../support/**/*.rb', __FILE__)) do |file|
  require file
end
