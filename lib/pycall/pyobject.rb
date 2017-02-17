module PyCall
  Py_EQ = 2

  module PyObjectMethods
    def ==(other)
      return false unless other.kind_of?(PyObject)
      return super if self.null? || other.null?
      case LibPython.PyObject_RichCompareBool(self, other, Py_EQ)
      when 0
        false
      when 1
        true
      else
        super
      end
    end

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

  class PyObject < FFI::Struct
    include PyObjectMethods

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
