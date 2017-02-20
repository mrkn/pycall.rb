module PyCall
  Py_LT = 0
  Py_LE = 1
  Py_EQ = 2
  Py_NE = 3
  Py_GT = 4
  Py_GE = 5

  RICH_COMPARISON_OPCODES = {
    :<  => Py_LT,
    :<= => Py_LE,
    :== => Py_EQ,
    :!= => Py_NE,
    :>  => Py_GT,
    :>= => Py_GE
  }.freeze

  module PyObjectMethods
    def rich_compare(other, op)
      opcode = RICH_COMPARISON_OPCODES[op]
      raise ArgumentError, "Unknown comparison op: #{op}" unless opcode

      other = Conversions.from_ruby(other) unless other.kind_of?(PyObject)
      return other.null? if self.null?
      return false if other.null?

      value = LibPython.PyObject_RichCompare(self, other, opcode)
      raise "Unable to compare: #{self} #{op} #{other}" if value.null?
      value.to_ruby
    end

    RICH_COMPARISON_OPCODES.keys.each do |op|
      define_method(op) {|other| rich_compare(other, op) }
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

    alias __aref__ []
    alias __aset__ []=

    def [](index)
      PyCall.getitem(self, index)
    end

    def []=(index, value)
      PyCall.setitem(self, index, value)
    end

    def +(other)
      value = LibPython.PyNumber_Add(self, other)
      return value.to_ruby unless value.null?
      raise "Unable to add #{self} and #{other}" # TODO: PyError
    end

    def -(other)
      value = LibPython.PyNumber_Subtract(self, other)
      return value.to_ruby unless value.null?
      raise "Unable to subtract #{self} and #{other}" # TODO: PyError
    end

    def *(other)
      value = LibPython.PyNumber_Multiply(self, other)
      return value.to_ruby unless value.null?
      raise "Unable to multiply #{self} and #{other}" # TODO: PyError
    end

    def /(other)
      value = LibPython.PyNumber_TrueDivide(self, other)
      return value.to_ruby unless value.null?
      raise "Unable to divide #{self} and #{other}" # TODO: PyError
    end

    def coerce(other)
      [Conversions.from_ruby(other), self]
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
      if PyCall.hasattr?(self, name)
        PyCall.getattr(self, name)
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

  def self.getattr(pyobj, name, default=nil)
    name = check_attr_name(name)
    value = LibPython.PyObject_GetAttrString(pyobj, name)
    if value.null?
      return default if default
      raise 'No attributes error' # TODO: implement PyError
    end
    value.to_ruby
  end

  def self.setattr(pyobj, name, value)
    name = check_attr_name(name)
    value = Conversions.from_ruby(value)
    return self unless LibPython.PyObject_SetAttrString(pyobj, name, value) == -1
    raise "Unable to set attribute `#{name}`" # TODO: implement PyError
  end

  def self.hasattr?(pyobj, name)
    name = check_attr_name(name)
    1 == LibPython.PyObject_HasAttrString(pyobj, name)
  end

  def self.check_attr_name(name)
    return name.to_str if name.respond_to? :to_str
    return name.to_s if name.kind_of? Symbol
    raise TypeError, "attribute name must be a String or a Symbol: #{name.inspect}"
  end
  private_class_method :check_attr_name

  def self.getitem(pyobj, key)
    pykey = Conversions.from_ruby(key)
    value = LibPython.PyObject_GetItem(pyobj, pykey)
    return value.to_ruby unless value.null?
    raise "Unable to getitem for #{pyobj} with #{key}" # TODO: implement PyError
  end

  def self.setitem(pyobj, key, value)
    pykey = Conversions.from_ruby(key)
    value = Conversions.from_ruby(value)
    return self unless LibPython.PyObject_SetItem(pyobj, pykey, value) == -1
    raise "Unable to setitem for #{pyobj} with #{key}" # TODO: implement PyError
  end
end
