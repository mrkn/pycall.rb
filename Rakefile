require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/extensiontask"

Dir[File.expand_path('../tasks/**/*.rake', __FILE__)].each {|f| load f }

Rake::ExtensionTask.new('pycall/pyptr')
RSpec::Core::RakeTask.new(:spec)

task :default => :spec
