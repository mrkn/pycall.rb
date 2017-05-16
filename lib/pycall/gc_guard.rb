require 'pycall'

module PyCall
  module GCGuard
    @gc_guard = {}

    class Key < Struct.new(:pyptr)
      def initialize(pyptr)
        self.pyptr = check_pyptr(pyptr)
        # LibPython.Py_IncRef(pyptr)
      end

      def release
        # LibPython.Py_DecRef(pyptr)
        self.pyptr = nil
      end

      def ==(other)
        case other
        when Key
          pyptr.pointer == other.pyptr.pointer
        else
          super
        end
      end

      alias :eql? :==

      def hash
        pyptr.pointer.address
      end

      private

      def check_pyptr(pyptr)
        pyptr = pyptr.__pyobj__ if pyptr.respond_to? :__pyobj__
        return pyptr if pyptr.kind_of? LibPython::PyObjectStruct
        raise TypeError, "The argument must be a Python object"
      end
    end

    def self.register(pyobj, obj)
      key = Key.new(pyobj)
      @gc_guard[key] ||= []
      @gc_guard[key] << obj
    end

    def self.unregister(pyobj)
      key = Key.new(pyobj)
      @gc_guard.delete(key).tap { key.release }
    end

    def self.guarded_object_count
      @gc_guard.length
    end
  end

  private_constant :GCGuard
end
