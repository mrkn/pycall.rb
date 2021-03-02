require "bundler/gem_helper"
require "rake/clean"

base_dir = File.join(File.dirname(__FILE__))

helper = Bundler::GemHelper.new(base_dir)
helper.install
spec = helper.gemspec

def run_extconf(build_dir, extension_dir, *arguments)
  cd(build_dir) do
    ruby(File.join(extension_dir, "extconf.rb"), *arguments)
  end
end

Dir[File.expand_path('../tasks/**/*.rake', __FILE__)].each {|f| load f }

spec.extensions.each do |extension|
  extension_dir = File.join(base_dir, File.dirname(extension))
  build_dir = ENV["BUILD_DIR"]
  if build_dir
    build_dir = File.join(build_dir, "pycall")
    directory build_dir
  else
    build_dir = extension_dir
  end

  makefile = File.join(build_dir, "Makefile")
  file makefile => build_dir do
    run_extconf(build_dir, extension_dir)
  end

  CLOBBER << makefile
  CLOBBER << File.join(build_dir, "mkmf.log")

  desc "Configure"
  task configure: makefile

  desc "Compile"
  task compile: makefile do
    cd(build_dir) do
      sh("make")
    end
  end

  task :clean do
    cd(build_dir) do
      sh("make", "clean") if File.exist?("Makefile")
    end
  end
end

require "rake/extensiontask"
Rake::ExtensionTask.new("pycall/spec_helper")

desc "Run tests"
task :test do
  cd(base_dir) do
    ruby("test/run-test.rb")
  end
end

task default: :test

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec) do |t|
  ext_dir = File.join(base_dir, "ext/pycall")
  t.ruby_opts = "-I#{ext_dir}"
  t.verbose = true
end

task default: :spec
task spec: :compile
