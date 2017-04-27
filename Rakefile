require "bundler/gem_tasks"
require "rspec/core/rake_task"

Dir[File.expand_path('../tasks/**/*.rake', __FILE__)].each {|f| load f }

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
