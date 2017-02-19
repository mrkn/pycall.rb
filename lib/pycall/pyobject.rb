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
      case key
      when String, Symbol
        LibPython.PyObject_GetAttrString(self, key.to_s).to_ruby
      else
        raise TypeError, "key must be a String"
      end
    end

    def []=(key, value)
      case key
      when String, Symbol
        value = Conversions.from_ruby(value)
        LibPython.PyObject_SetAttrString(self, key.to_s, value)
      else
        raise TypeError, "key must be a String"
      end
      self
    end

    def call(*args, **kwargs)
      args = PyCall::Tuple[*args]
      kwargs = if kwargs.empty?
                 PyObject.new(FFI::Pointer::NULL)
               else
                 PyCall::Dict.new(kwargs).__pyobj__
               end
      res = LibPython.PyObject_Call(self, args.__pyobj__, kwargs)
      res.to_ruby
    end

    def method_missing(name, *args, **kwargs)
      if 1 == LibPython.PyObject_HasAttrString(self, name.to_s)
        self[name]
      else
        super
      end
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
end
