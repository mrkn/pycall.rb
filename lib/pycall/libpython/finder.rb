require 'pycall/error'
require 'fiddle'

module PyCall
  module LibPython
    module Finder
      case RUBY_PLATFORM
      when /cygwin/
        libprefix = 'cyg'
        libsuffix = 'dll'
      when /mingw/, /mswin/
        libprefix = ''
        libsuffix = 'dll'
      when /darwin/
        libsuffix = 'dylib'
      end

      LIBPREFIX = libprefix || 'lib'
      LIBSUFFIX = libsuffix || 'so'

      class << self
        DEFAULT_PYTHON = [
          -'python3',
          -'python',
        ].freeze

        def find_python_config(python = nil)
          python ||= DEFAULT_PYTHON
          Array(python).each do |python_cmd|
            python_config = investigate_python_config(python_cmd)
            return [python_cmd, python_config] unless python_config.empty?
          end
        rescue
          raise ::PyCall::PythonNotFound
        else
          raise ::PyCall::PythonNotFound
        end

        def find_libpython(python = nil)
          debug_report("find_libpython(#{python.inspect})")
          python, python_config = find_python_config(python)

          set_PYTHONHOME(python_config)
          libs = make_libs(python_config)
          libpaths = make_libpaths(python_config)

          # Try LIBPYTHON environment variable first.
          if (libpython = ENV['LIBPYTHON'])
            if File.file?(libpython)
              begin
                return dlopen(libpython)
              rescue Fiddle::DLError
                debug_report "#{$!.class}: #{$!.message}"
              else
                debug_report "Success to dlopen #{libpython.inspect} from ENV['LIBPYTHON']"
              end
            end
            warn "WARNING(#{self}.#{__method__}) Ignore the wrong libpython location specified in ENV['LIBPYTHON']."
          end

          # Find libpython (we hope):
          multiarch = python_config[:MULTIARCH] || python_config[:multiarch]
          libs.each do |lib|
            libpaths.each do |libpath|
              libpath_libs = [ File.join(libpath, lib) ]
              libpath_libs << File.join(libpath, multiarch, lib) if multiarch
              libpath_libs.each do |libpath_lib|
                [ libpath_lib, "#{libpath_lib}.#{LIBSUFFIX}" ].each do |fullname|
                  unless File.file? fullname
                    debug_report "Unable to find #{fullname}"
                    next
                  end
                  begin
                    return dlopen(libpath_lib)
                  rescue Fiddle::DLError
                    debug_report "#{$!.class}: #{$!.message}"
                  else
                    debug_report "Success to dlopen #{libpaht_lib}"
                  end
                end
              end
            end
          end

          # Find libpython in the system path
          libs.each do |lib|
            begin
              return dlopen(lib)
            rescue Fiddle::DLError
              debug_report "#{$!.class}: #{$!.message}"
            else
              debug_report "Success to dlopen #{lib}"
            end
          end

          raise ::PyCall::PythonNotFound
        end

        def investigate_python_config(python)
          python_env = { 'PYTHONIOENCODING' => 'UTF-8' }
          debug_report("investigate_python_config(#{python.inspect})")
          IO.popen(python_env, [python, python_investigator_py], 'r') do |io|
            {}.tap do |config|
              io.each_line do |line|
                next unless line =~ /: /
                key, value = line.chomp.split(': ', 2)
                case value
                when 'True', 'true', 'False', 'false'
                  value = (value == 'True' || value == 'true')
                end
                config[key.to_sym] = value if value != 'None'
              end
            end
          end
        rescue Errno::ENOENT
          raise PyCall::PythonInvestigationFailed
        end

        def python_investigator_py
          File.expand_path('../../python/investigator.py', __FILE__)
        end

        def set_PYTHONHOME(python_config)
          if !ENV.has_key?('PYTHONHOME') && python_config[:conda]
            case RUBY_PLATFORM
            when /mingw32/, /cygwin/, /mswin/
              ENV['PYTHONHOME'] = python_config[:exec_prefix]
            else
              ENV['PYTHONHOME'] = python_config.values_at(:prefix, :exec_prefix).join(':')
            end
          end
        end

        def make_libs(python_config)
          libs = []
          %i(INSTSONAME LDLIBRARY).each do |key|
            lib = python_config[key]
            libs << lib << File.basename(lib) if lib
          end
          if (lib = python_config[:LIBRARY])
            libs << File.basename(lib, File.extname(lib))
          end

          v = python_config[:VERSION]
          libs << "#{LIBPREFIX}python#{v}" << "#{LIBPREFIX}python"
          libs.uniq!

          debug_report "libs: #{libs.inspect}"
          return libs
        end

        def make_libpaths(python_config)
          executable = python_config[:executable]
          libpaths = [ python_config[:LIBDIR] ]
          if Fiddle::WINDOWS
            libpaths << File.dirname(executable)
          else
            libpaths << File.expand_path('../../lib', executable)
          end
          libpaths << python_config[:PYTHONFRAMEWORKPREFIX]
          exec_prefix = python_config[:exec_prefix]
          libpaths << exec_prefix << File.join(exec_prefix, 'lib')
          libpaths.compact!

          debug_report "libpaths: #{libpaths.inspect}"
          return libpaths
        end

        private

        def dlopen(libname)
          Fiddle.dlopen(libname).tap do |handle|
            debug_report("dlopen(#{libname.inspect}) = #{handle.inspect}") if handle
          end
        end

        def debug_report(message)
          return unless debug?
          $stderr.puts "DEBUG(find_libpython) #{message}"
        end

        def debug?
          @debug ||= (ENV['PYCALL_DEBUG_FIND_LIBPYTHON'] == '1')
        end
      end
    end
  end
end
