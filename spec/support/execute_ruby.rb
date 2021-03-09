require 'rbconfig'
require 'open3'

module PyCall
  module RSpecHelper
    module ExecuteRuby
      RUBYLIB = ENV["RUBYLIB"]

      def ruby(script)
        child_env = {}
        base_dir = File.expand_path("../../..", __FILE__)
        lib_dir = File.join(base_dir, "lib")
        ext_dir = File.join(base_dir, "ext/pycall")
        child_env["RUBYLIB"] = [lib_dir, ext_dir, RUBYLIB].join(File::PATH_SEPARATOR)
        Open3.capture3(child_env, ruby_path, stdin_data: <<SCRIPT)
require 'bundler'
Bundler.setup

#{script}
SCRIPT
      end

      private

      def ruby_path
        RbConfig.ruby
      end
    end
  end
end

RSpec.configuration.include PyCall::RSpecHelper::ExecuteRuby
