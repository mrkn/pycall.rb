require 'pycall/wrapper_object_cache'

module PyCall
  module PyObjectWrapper
    attr_reader :__pyptr__

    def self.extend_object(obj)
      pyptr = obj.instance_variable_get(:@__pyptr__)
      unless pyptr.kind_of? PyPtr
        raise TypeError, "@__pyptr__ should have PyCall::PyPtr object"
      end
      super
    end

    OPERATOR_METHOD_NAMES = {
      :+ => :__add__,
      :- => :__sub__,
      :* => :__mul__,
      :/ => :__truediv__
    }.freeze

    def method_missing(name, *args)
      name_str = name.to_s if name.kind_of?(Symbol)
      name_str.chop! if name_str.end_with?('=')
      case name
      when :+, :-, :*, :/
        op_name = OPERATOR_METHOD_NAMES[name]
        if LibPython::Helpers.hasattr?(__pyptr__, op_name)
          LibPython::Helpers.define_wrapper_method(self, op_name)
          singleton_class.__send__(:alias_method, name, op_name)
          return self.__send__(name, *args)
        end
      else
        if LibPython::Helpers.hasattr?(__pyptr__, name_str)
          LibPython::Helpers.define_wrapper_method(self, name)
          return self.__send__(name, *args)
        end
      end
      super
    end

    def respond_to_missing?(name, include_private)
      return true if LibPython::Helpers.hasattr?(__pyptr__, name)
      super
    end

    def ==(other)
      case other
      when PyObjectWrapper
        LibPython::Helpers.compare(:==, __pyptr__, other.__pyptr__)
      else
        super
      end
    end

    def [](*key)
      if key.length == 1
        key = key[0]
      else
        keys = PyCall::Tuple.new(key)
      end
      LibPython::Helpers.getitem(__pyptr__, key)
    end

    def []=(*key, value)
      if key.length == 1
        key = key[0]
      else
        key = PyCall::Tuple.new(key)
      end
      LibPython::Helpers.setitem(__pyptr__, key, value)
    end

    def call(*args)
      LibPython::Helpers.call_object(__pyptr__, *args)
    end

    class SwappedOperationAdapter
      def initialize(obj)
        @obj = obj
      end

      attr_reader :obj

      def +(other)
        other.__radd__(self.obj)
      end

      def -(other)
        other.__rsub__(self.obj)
      end

      def *(other)
        other.__rmul__(self.obj)
      end

      def /(other)
        other.__rtruediv__(self.obj)
      end
    end

    def coerce(other)
      [SwappedOperationAdapter.new(other), self]
    end

    def dup
      super.tap do |duped|
        copied = PyCall.import_module('copy').copy(__pyptr__)
        copied = copied.__pyptr__ if copied.kind_of? PyObjectWrapper
        duped.instance_variable_set(:@__pyptr__, copied)
      end
    end

    def to_s
      LibPython::Helpers.str(__pyptr__)
    end

    def to_i
      LibPython::Helpers.call_object(PyCall::builtins.int.__pyptr__, __pyptr__)
    end

    def to_f
      LibPython::Helpers.call_object(PyCall::builtins.float.__pyptr__, __pyptr__)
    end
  end

  module_function

  class WrapperModuleCache < WrapperObjectCache
    def initialize
      super(LibPython::API::PyModule_Type)
    end

    def check_wrapper_object(wrapper_object)
      unless wrapper_object.kind_of?(Module) && wrapper_object.kind_of?(PyObjectWrapper)
        raise TypeError, "unexpected type #{wrapper_object.class} (expected Module extended by PyObjectWrapper)"
      end
    end

    def self.instance
      @instance ||= self.new
    end
  end

  private_constant :WrapperModuleCache

  def wrap_module(pymodptr)
    check_ismodule(pymodptr)
    WrapperModuleCache.instance.lookup(pymodptr) do
      Module.new do |mod|
        mod.instance_variable_set(:@__pyptr__, pymodptr)
        mod.extend PyObjectWrapper
      end
    end
  end

  def check_isclass(pyptr)
    pyptr = pyptr.__pyptr__ if pyptr.kind_of? PyObjectWrapper
    return if pyptr.kind_of? LibPython::API::PyType_Type
    return defined?(LibPython::API::PyClass_Type) && pyptr.kind_of?(LibPython::API::PyClass_Type)
    raise TypeError, "PyType object is required"
  end

  def check_ismodule(pyptr)
    return if pyptr.kind_of? LibPython::API::PyModule_Type
    raise TypeError, "PyModule object is required"
  end
end
