module PyCall
  HASH_SALT = "PyCall::PyObject".hash

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

  module PyObjectWrapper
    module ClassMethods
      private

      def wrap_class(pyclass)
        pyclass__pyobj__ = pyclass.__pyobj__
        define_singleton_method(:__pyobj__) { pyclass__pyobj__ }

        PyCall.dir(__pyobj__).each do |name|
          obj = PyCall.getattr(__pyobj__, name)
          next unless obj.kind_of?(PyCall::PyObject) || obj.kind_of?(PyCall::PyObjectWrapper)
          next unless PyCall.callable?(obj)

          define_method(name) do |*args, **kwargs|
            PyCall.getattr(__pyobj__, name).(*args, **kwargs)
          end
        end

        class << self
          def method_missing(name, *args, **kwargs)
            return super unless PyCall.hasattr?(__pyobj__, name)
            PyCall.getattr(__pyobj__, name)
          end
        end

        PyCall::Conversions.python_type_mapping(__pyobj__, self)
      end
    end

    def self.included(mod)
      mod.extend ClassMethods
    end

    def initialize(pyobj)
      pyobj = LibPython::PyObjectStruct.new(pyobj) if pyobj.kind_of? FFI::Pointer
      pyobj = pyobj.__pyobj__ unless pyobj.kind_of? LibPython::PyObjectStruct
      @__pyobj__ = pyobj
    end

    attr_reader :__pyobj__

    def eql?(other)
      rich_compare(other, :==)
    end

    def hash
      hash_value = LibPython.PyObject_Hash(__pyobj__)
      return super if hash_value == -1
      hash_value
    end

    def type
      LibPython.PyObject_Type(__pyobj__).to_ruby
    end

    def null?
      __pyobj__.null?
    end

    def to_ptr
      __pyobj__.to_ptr
    end

    def py_none?
      to_ptr == PyCall.None.to_ptr
    end

    def kind_of?(klass)
      case klass
      when PyObjectWrapper
        __pyobj__.kind_of? klass.__pyobj__
      when LibPython::PyObjectStruct
        __pyobj__.kind_of? klass
      else
        super
      end
    end

    def rich_compare(other, op)
      opcode = RICH_COMPARISON_OPCODES[op]
      raise ArgumentError, "Unknown comparison op: #{op}" unless opcode

      other = Conversions.from_ruby(other)
      return other.null? if __pyobj__.null?
      return false if other.null?

      value = LibPython.PyObject_RichCompare(__pyobj__, other, opcode)
      raise "Unable to compare: #{self} #{op} #{other}" if value.null?
      value.to_ruby
    end

    RICH_COMPARISON_OPCODES.keys.each do |op|
      define_method(op) {|other| rich_compare(other, op) }
    end

    def [](*indices)
      if indices.length == 1
        indices = indices[0]
      else
        indices = PyCall.tuple(*indices)
      end
      PyCall.getitem(self, indices)
    end

    def []=(*indices_and_value)
      value = indices_and_value.pop
      indices = indices_and_value
      if indices.length == 1
        indices = indices[0]
      else
        indices = PyCall.tuple(*indices)
      end
      PyCall.setitem(self, indices, value)
    end

    def +(other)
      other = Conversions.from_ruby(other)
      value = LibPython.PyNumber_Add(__pyobj__, other)
      return value.to_ruby unless value.null?
      raise PyError.fetch
    end

    def -(other)
      other = Conversions.from_ruby(other)
      value = LibPython.PyNumber_Subtract(__pyobj__, other)
      return value.to_ruby unless value.null?
      raise PyError.fetch
    end

    def *(other)
      other = Conversions.from_ruby(other)
      value = LibPython.PyNumber_Multiply(__pyobj__, other)
      return value.to_ruby unless value.null?
      raise PyError.fetch
    end

    def /(other)
      other = Conversions.from_ruby(other)
      value = LibPython.PyNumber_TrueDivide(__pyobj__, other)
      return value.to_ruby unless value.null?
      raise PyError.fetch
    end

    def **(other)
      other = Conversions.from_ruby(other)
      value = LibPython.PyNumber_Power(__pyobj__, other, PyCall.None)
      return value.to_ruby unless value.null?
      raise PyError.fetch
    end

    def coerce(other)
      [PyObject.new(Conversions.from_ruby(other)), self]
    end

    def call(*args, **kwargs)
      args = PyCall::Tuple[*args]
      kwargs = kwargs.empty? ? PyObject.null : PyCall::Dict.new(kwargs)
      res = LibPython.PyObject_Call(__pyobj__, args.__pyobj__, kwargs.__pyobj__)
      return res.to_ruby if LibPython.PyErr_Occurred().null?
      raise PyError.fetch
    end

    def method_missing(name, *args, **kwargs)
      name_s = name.to_s
      if name_s.end_with? '='
        name = name_s[0..-2]
        if PyCall.hasattr?(__pyobj__, name.to_s)
          PyCall.setattr(__pyobj__, name, args.first)
        else
          raise NameError, "object has no attribute `#{name}'"
        end
      elsif PyCall.hasattr?(__pyobj__, name.to_s)
        PyCall.getattr(__pyobj__, name)
      else
        super
      end
    end

    def to_s
      s = LibPython.PyObject_Repr(__pyobj__)
      if s.null?
        LibPython.PyErr_Clear()
        s = LibPython.PyObject_Str(__pyobj__)
        if s.null?
          LibPython.PyErr_Clear()
          return super
        end
      end
      s.to_ruby
    end

    alias inspect to_s
  end
end
