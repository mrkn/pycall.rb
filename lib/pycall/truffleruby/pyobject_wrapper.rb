module PyCall
  class PyObjectWrapper
    attr_reader :__pyptr__

    def __pyptr__
      @__pyptr__
    end

    def initialize(foreign)
      @__pyptr__ = foreign
      PyCall::Conversion.register_python_type_mapping(@__pyptr__, self)
    end

    def self.extend_object(obj)
      pyptr = obj.instance_variable_get(:@__pyptr__)
      unless pyptr.kind_of? PyPtr
        raise TypeError, "@__pyptr__ should have PyCall::PyPtr object"
      end
      super
    end

    # todo test
    def self.wrap(something)
      if Truffle::Interop.foreign?(something)
        wrapper = Conversion.to_ruby(something)
        if wrapper.nil?
          wrapper = private_wrap(something)
          if wrapper.nil? || wrapper != false
            type = Conversion.get_type(something)
            Conversion.register_python_type_mapping(type, wrapper.class)
          end
        end
        wrapper
      else
        something
      end
    end

    def self.private_wrap(something)
      return something.to_s if Truffle::Interop.is_string?(something)
      return nil if Truffle::Interop.null?(something)
      @@list_type ||= Polyglot.eval("python", "list")
      @@python_complex_class ||= Polyglot.eval('python', 'complex')
      @@python_isinstance ||= Polyglot.eval('python', 'isinstance')
      return PyCall.from_py_complex(something) if @@python_isinstance.call(something, @@python_complex_class)
      if Truffle::Interop.foreign?(something)
        if @@python_isinstance.call(something, @@list_type)
          List.new(something)
        else
          self.new(something)
        end
      end
      something
    end

    # todo test
    def self.unwrap(obj)
      if obj.nil? 
        PyCall::LibPython::API::None.__pyptr__
      elsif obj.kind_of?(PyCall::Tuple)
        obj.__pyptr__
      elsif obj.is_a?(Complex)
        PyCall.to_py_complex(obj)
      elsif obj.is_a?(Enumerable)
        obj.map { |part| self.unwrap(part) }
      elsif obj.is_a?(PyObjectWrapper)
        self.unwrap(obj.__pyptr__)
      else
        obj
      end
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
      obj_attr = @__pyptr__[name]
      if PyCall.callable?(obj_attr)
        @@python_isclass ||= Polyglot.eval('python', 'import inspect; inspect.isclass')
        if @@python_isclass.call(obj_attr)
          return PyTypeObjectWrapper.wrap_class(obj_attr) #Class, imitate PyCalls behaviour by not calling Class, instead wrapping it
        else
          PyObjectWrapper.wrap(obj_attr.call(*args)) #normal method call
        end
      else
        PyObjectWrapper.wrap(obj_attr) #Return attribute, no method call
      end
    end

    def respond_to_missing?(name, include_private)
      return true if PyCall.hasattr?(@__pyptr__, name)
      super
    end

    def kind_of?(cls)
      @@python_isinstance ||= Polyglot.eval('python', 'isinstance')
      case#maybe not no nice, but case cls does === comparison, and PyCall::Tuple === PyCall::Tuple is false
      when cls == Module
        true #required for tests
      when cls == PyCall::PyPtr
        true #required for tests
      when cls == PyCall::Tuple
        @@python_tupleclass ||= Polyglot.eval('python', 'tuple')
        @@python_isinstance.call(@__pyptr__, @@python_tupleclass)
      when cls == PyTypeObjectWrapper  # todo ==> PyObjectWrapper
        @@python_isinstance.call(@__pyptr__, cls.__pyptr__)
      when cls == PyObjectWrapper
        true #@@python_isinstance.call(@__pyptr__, Conversion.get_type.cls.py)
      end
    end

    def none?
      Truffle::Interop.null?(@__pyptr__)
    end

    def nil?
      Truffle::Interop.null?(@__pyptr__)
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
            @@pythonop_#{pythonop}.call(__pyptr__, other.__pyptr__)
          else
            @@pythonop_#{pythonop}.call(__pyptr__, other)
          end
        end
      end;
    end

    def [](*key)
      if key.length > 0 && key[0].is_a?(PyCall::Slice)
        return PyCall::List.new(__pyptr__.__getitem__(key[0].__pyptr__))
      else
        begin
          return PyObjectWrapper.wrap(__pyptr__.__getitem__(key[0]))
        rescue => e
          return PyObjectWrapper.wrap(__pyptr__.__getattribute__(key[0]))
        end
      end
    end

    def []=(*key, value)
      begin
        __pyptr__.__setitem__(key[0], value)
      rescue => e
        __pyptr__.__setattr__(key[0] , value)
      end
    end

    def call(*args)
      __pyptr__.call(*args)
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
      [SwappedOperationAdapter.new(@__pyptr__), self]
    end

    def dup
      super.tap do |duped|
        copied = PyCall.import_module('copy').copy(__pyptr__)
        copied = copied.__pyptr__ if copied.kind_of? PyObjectWrapper
        duped.instance_variable_set(:@__pyptr__, copied)
      end
    end

    def inspect
      PyCall.builtins.repr(@__pyptr__)
    end

    def to_s
      @@python_str ||= Polyglot.eval('python', 'str')
      @@python_str.call(@__pyptr__)
    end

    def to_i
      @@python_int ||= Polyglot.eval('python', 'int')
      @@python_int.call(@__pyptr__)
    end

    def to_f
      @@python_float ||= Polyglot.eval('python', 'float')
      @@python_float.call(@__pyptr__)
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
