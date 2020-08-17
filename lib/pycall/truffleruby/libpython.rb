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
      def self.getattr(obj, name)
        PyCall.getattr(obj, name)
      end
      def self.callable?(pyobj)
        PyCall.callable?(pyobj)
      end
      def self.import_module(name)
        PyCall.import_module(name)
      end
    end

    module API
      const_set(:None, PyCall::PyObjectWrapper.new(Polyglot.eval('python', 'None')))

      def self.builtins_module_ptr
        PyCall.builtins.__pyptr__
      end

      class PyBool_Type
      end

      class PyDict_Type
      end

      class PyString_Type
      end

      class PyFloat_Type
      end
    end

    const_set(:PYTHON_VERSION, Polyglot.eval('python', 'import sys;sys.version.split(" ")[0]'))
    const_set(:PYTHON_DESCRIPTION, Polyglot.eval('python', 'import sys;sys.version'))
  end

end