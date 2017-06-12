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

    def self.embed(pyobj, obj)
      pyptr = pyobj.respond_to?(:__pyobj__) ? pyobj.__pyobj__ : pyobj
      raise TypeError, "The argument must be a Python object" unless pyptr.kind_of? LibPython::PyObjectStruct
      wo = LibPython.PyWeakref_NewRef(pyptr, weakref_callback)
      register(wo, obj)
      pyobj
    end

    private_class_method def self.weakref_callback
      unless @weakref_callback
        @weakref_callback_func = FFI::Function.new(
          LibPython::PyObjectStruct.ptr,
          [LibPython::PyObjectStruct.ptr, LibPython::PyObjectStruct.ptr]
        ) do |callback, pyptr|
          GCGuard.unregister(pyptr)
          # LibPython.Py_DecRef(pyptr)
          # LibPython.Py_IncRef(PyCall.None)
          next PyCall.None
        end
        method_def = LibPython::PyMethodDef.new("weakref_callback", @weakref_callback_func, LibPython::METH_O, nil)
        @weakref_callback = LibPython.PyCFunction_NewEx(method_def, nil, nil).tap {|po| LibPython.Py_IncRef(po) }
      end
      @weakref_callback
    end
  end

  private_constant :GCGuard
end
