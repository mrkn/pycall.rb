require "bundler"
Bundler::GemHelper.install_tasks

require "rake"
require "rake/extensiontask"
require "rspec/core/rake_task"

Dir[File.expand_path('../tasks/**/*.rake', __FILE__)].each {|f| load f }

gem_spec = eval(File.read('pycall.gemspec'))
Rake::ExtensionTask.new('pycall', gem_spec) do |ext|
  ext.lib_dir = File.join(*['lib', ENV['FAT_DIR']].compact)
  ext.cross_compile = true
  ext.cross_platform = %w[x86-mingw32 x64-mingw32]
  ext.cross_compiling do |s|
    s.files.concat %w[lib/2.2/pycall.so lib/2.3/pycall.so lib/2.4/pycall.so]
  end
end

Rake::ExtensionTask.new('pycall/spec_helper')

desc "Compile binaries for mingw platform using rake-compiler-dock"
task 'build:mingw' do
  require 'rake_compiler_dock'
  RakeCompilerDock.sh "bundle && rake cross native gem RUBY_CC_VERSION=2.1.6:2.2.2:2.3.0:2.4.0"
end

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
task spec: :compile
