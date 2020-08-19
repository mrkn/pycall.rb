module PyCall
  module LibPython
    module Finder
    end

    module Helpers
      def self.unicode_literals?
        nil
      end

      #Why are those methods also duplicated in normal pycall?
      def self.hasattr?(obj, name)
        PyCall.hasattr?(obj, name)
      end

      def self.getattr(*args)
        begin
          PyCall.getattr(args[0], args[1])
        rescue => e
          return args[2] if args.length > 2 #default value in case attr does not exist
          raise e
        end
      end

      def self.callable?(pyobj)
        PyCall.callable?(pyobj)
      end
      def self.import_module(name)
        PyCall.import_module(name)
      end

      def self.call_object(*args)
        #This is a stub, used for indexing
      end
    end

    module API
      const_set(:None, PyCall::PyPtr.new(Polyglot.eval('python', 'None')))
      const_set(:ForeignNone, Polyglot.eval('python', 'None'))
      def self.builtins_module_ptr
        PyCall.builtins.__pyptr__
      end

      class PyBool_Type
      end

      class PyDict_Type
      end

      class PyList_Type
      end

      class PyString_Type
      end

      class PyUnicode_Type
      end

      class PyFloat_Type
      end
    end

    const_set(:PYTHON_VERSION, Polyglot.eval('python', 'import sys;sys.version.split(" ")[0]'))
    const_set(:PYTHON_DESCRIPTION, Polyglot.eval('python', 'import sys;sys.version'))
  end

end