require 'ffi'

module PyCall
  module LibPython
    extend FFI::Library

    private_class_method

    def self.find_libpython(python = nil)
      python ||= 'python'
      python_config = investigate_python_config(python)

      v = python_config[:VERSION]
      libprefix = FFI::Platform::LIBPREFIX
      libs = [ "#{libprefix}python#{v}", "#{libprefix}python" ]
      lib = python_config[:LIBRARY]
      libs.unshift(File.basename(lib, File.extname(lib))) if lib
      lib = python_config[:LDLIBRARY]
      libs.unshift(lib, File.basename(lib)) if lib
      libs.uniq!

      executable = python_config[:executable]
      libpaths = [ python_config[:LIBDIR] ]
      if FFI::Platform.windows?
        libpaths << dirname(executable)
      else
        libpaths << File.expand_path('../../lib', executable)
      end
      libpaths << python_config[:PYTHONFRAMEWORKPREFIX] if FFI::Platform.mac?

      exec_prefix = python_config[:exec_prefix]
      libpaths << exec_prefix << File.join(exec_prefix, 'lib')

      unless ENV['PYTHONHOME']
        # PYTHONHOME tells python where to look for both pure python and binary modules.
        # When it is set, it replaces both `prefix` and `exec_prefix`
        # and we thus need to set it to both in case they differ.
        # This is also what the documentation recommends.
        # However, they are documented to always be the same on Windows,
        # where it causes problems if we try to include both.
        if FFI::Platform.windows?
          ENV['PYTHONHOME'] = exec_prefix
        else
          ENV['PYTHONHOME'] = [python_config[:prefix], exec_prefix].join(':')
        end

        # Unfortunately, setting PYTHONHOME screws up Canopy's Python distribution?
        unless system(python, '-c', 'import site', out: File::NULL, err: File::NULL)
          ENV['PYTHONHOME'] = nil
        end
      end

      # Find libpython (we hope):
      libsuffix = FFI::Platform::LIBSUFFIX
      libs.each do |lib|
        libpaths.each do |libpath|
          libpath_lib = File.join(libpath, lib)
          if File.file?("#{libpath_lib}.#{libsuffix}")
            ffi_lib "#{libpath_lib}.#{libsuffix}"
            return
          end
        end
      end
    end

    def self.investigate_python_config(python)
      python_env = { 'PYTHONIOENCODING' => 'UTF-8' }
      IO.popen(python_env, [python, python_investigator_py], 'r') do |io|
        {}.tap do |config|
          io.each_line do |line|
            key, value = line.chomp.split(': ', 2)
            config[key.to_sym] = value
          end
        end
      end
    end

    def self.python_investigator_py
      File.expand_path('../python/investigator.py', __FILE__)
    end

    ffi_lib_flags :lazy, :global
    find_libpython ENV['PYTHON']

    attach_function :Py_GetVersion, [], :string

    public_class_method
  end
end
