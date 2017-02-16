module PyCall
  class PyObject < FFI::Struct
    def py_none?
      to_ptr == LibPython.Py_None.to_ptr
    end

    def kind_of?(klass)
      case klass
      when PyTypeObject
        Types.pyisinstance(self, klass)
      else
        super
      end
    end
  end

  class PyTypeObject < FFI::Struct
    def ===(obj)
      obj.kind_of? self
    end

    def inspect
      "pytype(#{self[:tp_name]})"
    end
  end
end
