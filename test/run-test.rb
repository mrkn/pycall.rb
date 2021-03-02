#!/usr/bin/env ruby

$VERBOSE = true

require "fileutils"
require "pathname"

base_dir = Pathname.new(__dir__).parent.expand_path

lib_dir = base_dir + "lib"
ext_dir = base_dir + "ext" + "pycall"
test_dir = base_dir + "test"

build_dir = ENV["BUILD_DIR"]
if build_dir
  build_dir = File.join(build_dir, "memory-view-test-helper")
  FileUtils.mkdir_p(build_dir)
else
  build_dir = ext_dir
end

make = nil
if ENV["NO_MAKE"] != "yes"
  if ENV["MAKE"]
    make = ENV["MAKE"]
  elsif system("which gmake > #{File::NULL} 2>&1")
    make = "gmake"
  elsif system("which make > #{File::NULL} 2>&1")
    make = "make"
  end
end
if make
  Dir.chdir(build_dir.to_s) do
    unless File.exist?("Makefile")
      system(RbConfig.ruby,
             (ext_dir + "extconf.rb").to_s,
             "--enable-debug-build") or exit(false)
    end
    system(make) or exit(false)
  end
end

$LOAD_PATH.unshift(build_dir.to_s)
$LOAD_PATH.unshift(lib_dir.to_s)

require_relative "helper"

ENV["TEST_UNIT_MAX_DIFF_TARGET_STRING_SIZE"] ||= "10000"

exit(Test::Unit::AutoRunner.run(true, test_dir.to_s))
