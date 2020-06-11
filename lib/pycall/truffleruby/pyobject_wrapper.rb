module PyCall
  module PyObjectWrapper
    attr_reader :__foreignobj__

    def self.extend_object(obj)
      pyptr = obj.instance_variable_get(:@__foreignobj__)
      unless pyptr.kind_of? PyPtr
        raise TypeError, "@__foreignobj__ should have PyCall::PyPtr object"
      end
      super
    end

    OPERATOR_METHOD_NAMES = {
      :+  => :__add__,
      :-  => :__sub__,
      :*  => :__mul__,
      :/  => :__truediv__,
      :%  => :__mod__,
      :** => :__pow__,
      :<< => :__lshift__,
      :>> => :__rshift__,
      :&  => :__and__,
      :^  => :__xor__,
      :|  => :__or__
    }.freeze

    def method_missing(name, *args)
      name_str = name.to_s if name.kind_of?(Symbol)
      name_str.chop! if name_str.end_with?('=')
      case name
      when *OPERATOR_METHOD_NAMES.keys
        op_name = OPERATOR_METHOD_NAMES[name]
        if LibPython::Helpers.hasattr?(__foreignobj__, op_name)
          LibPython::Helpers.define_wrapper_method(self, op_name)
          singleton_class.__send__(:alias_method, name, op_name)
          return self.__send__(name, *args)
        end
      else
        if LibPython::Helpers.hasattr?(__foreignobj__, name_str)
          LibPython::Helpers.define_wrapper_method(self, name)
          return self.__send__(name, *args)
        end
      end
      super
    end

    def respond_to_missing?(name, include_private)
      return true if LibPython::Helpers.hasattr?(__foreignobj__, name)
      super
    end

    def kind_of?(cls)
      case cls
      when PyTypeObjectWrapper
        __foreignobj__.kind_of?(cls.__foreignobj__)
      else
        super
      end
    end

    {:==  => "eq",
    :!=   => "ne",
    :<    => "lt",
    :<=   => "le",
    :>    => "gt",
    :>=   => "ge"}.each do |op, pythonop|
      class_eval("#{<<-"begin;"}\n#{<<-"end;"}", __FILE__, __LINE__+1)
      begin;
        def #{op}(other)
          @@pythonop_#{pythonop} ||= Polyglot.eval('python', 'import operator;operator.#{pythonop}')
          case other
          when PyObjectWrapper
            @@pythonop_#{pythonop}.call(__foreignobj__, other.__foreignobj__)
          else
            @@pythonop_#{pythonop}.call(__foreignobj__, other)
          end
        end
      end;
    end

    def [](*key)
      LibPython::Helpers.getitem(__foreignobj__, key)
    end

    def []=(*key, value)
      LibPython::Helpers.setitem(__foreignobj__, key, value)
    end

    def call(*args)
      LibPython::Helpers.call_object(__foreignobj__, *args)
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

      def %(other)
        other.__rmod__(self.obj)
      end

      def **(other)
        other.__rpow__(self.obj)
      end

      def <<(other)
        other.__rlshift__(self.obj)
      end

      def >>(other)
        other.__rrshift__(self.obj)
      end

      def &(other)
        other.__rand__(self.obj)
      end

      def ^(other)
        other.__rxor__(self.obj)
      end

      def |(other)
        other.__ror__(self.obj)
      end
    end

    def coerce(other)
      [SwappedOperationAdapter.new(other), self]
    end

    def dup
      super.tap do |duped|
        copied = PyCall.import_module('copy').copy(__foreignobj__)
        copied = copied.__foreignobj__ if copied.kind_of? PyObjectWrapper
        duped.instance_variable_set(:@__foreignobj__, copied)
      end
    end

    def inspect
      PyCall.builtins.repr(__foreignobj__)
    end

    def to_s
      LibPython::Helpers.str(__foreignobj__)
    end

    def to_i
      LibPython::Helpers.call_object(PyCall::builtins.int.__foreignobj__, __foreignobj__)
    end

    def to_f
      LibPython::Helpers.call_object(PyCall::builtins.float.__foreignobj__, __foreignobj__)
    end
  end

  module_function

  def check_ismodule(pyptr)
    @@ismodule_py ||= Polyglot.eval('python', 'import inspect;inspect.ismodule')
    @@ismodule_py.call(pyptr)
  end

  def check_isclass(pyptr)
    @@isclass_py ||= Polyglot.eval('python', 'import inspect;inspect.isclass')
    @@isclass_py.call(pyptr)
  end
end
