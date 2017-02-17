module PyCall
  module PyObjectMethods
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

    def [](key)
      key = Conversions.from_ruby(key)
      LibPython.PyObject_GetItem(self, key)
    end

    def []=(key, value)
      key = Conversions.from_ruby(key)
      value = Conversions.from_ruby(value)
      LibPython.PyObject_SetItem(self, key, value)
      self
    end
  end

  class PyObject < FFI::Struct
    include PyObjectMethods
  end

  class PyTypeObject < FFI::Struct
    include PyObjectMethods

    def ===(obj)
      obj.kind_of? self
    end

    def inspect
      "pytype(#{self[:tp_name]})"
    end
  end

  def self.del_item(pyobj, key)
    key = Conversions.from_ruby(key)
    LibPython.PyObject_DelItem(pyobj, key)
  end
end
