require 'rbconfig'
require 'open3'

module PyCall
  module RSpecHelper
    module ExecuteRuby
      def ruby(script)
        Open3.capture3(ruby_path, stdin_data: <<SCRIPT)
require 'bundler'
Bundler.setup
$LOAD_PATH.unshift "#{File.expand_path('../../../lib', __FILE__)}"

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
