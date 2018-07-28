require 'pycall/pyobject_wrapper'

module PyCall
  module PyTypeObjectWrapper
    include PyObjectWrapper

    def self.extend_object(cls)
      unless cls.kind_of? Class
        raise TypeError, "PyTypeObjectWrapper cannot extend non-class objects"
      end
      pyptr = cls.instance_variable_get(:@__pyptr__)
      unless pyptr.kind_of? PyTypePtr
        raise TypeError, "@__pyptr__ should have PyCall::PyTypePtr object"
      end
      super
      cls.include PyObjectWrapper
    end

    def inherited(subclass)
      subclass.instance_variable_set(:@__pyptr__, __pyptr__)
    end

    def new(*args, &b)
      wrap_pyptr(__new__(__pyptr__, *args)).tap do |obj|
        obj.instance_eval { initialize(*args, &b) }
      end
    end

    def wrap_pyptr(pyptr)
      return pyptr if pyptr.class <= self
      pyptr = pyptr.__pyptr__ if pyptr.kind_of? PyObjectWrapper
      unless pyptr.kind_of? PyPtr
        raise TypeError, "unexpected argument type #{pyptr.class} (expected PyCall::PyPtr)"
      end
      unless pyptr.kind_of? __pyptr__
        raise TypeError, "unexpected argument Python type #{pyptr.__ob_type__.__tp_name__} (expected #{__pyptr__.__tp_name__})"
      end
      allocate.tap do |obj|
        obj.instance_variable_set(:@__pyptr__, pyptr)
      end
    end

    def ===(other)
      case other
      when PyObjectWrapper
        __pyptr__ === other.__pyptr__
      when PyPtr
        __pyptr__ === other
      else
        super
      end
    end

    def subclass?(other)
      case other
      when PyTypeObjectWrapper
        __pyptr__.subclass?(other.__pyptr__)
      when Class, Module
        other >= self || false
      else
        __pyptr__.subclass?(other)
      end
    end

    def <=>(other)
      return 0  if equal?(other)
      case other
      when PyTypeObjectWrapper
        return super if __pyptr__ == other.__pyptr__
        other = other.__pyptr__
      when Class, Module
        return -1 if subclass?(other)
        return 1  if other > self
      end

      return nil unless other.is_a?(PyTypePtr)
      return 0  if __pyptr__ == other
      return -1 if __pyptr__.subclass?(other)
      return 1  if other.subclass?(__pyptr__)
      nil
    end

    def <(other)
      cmp = self <=> other
      cmp && cmp < 0
    end

    def >(other)
      cmp = self <=> other
      cmp && cmp > 0
    end

    def <=(other)
      cmp = self <=> other
      cmp && cmp <= 0
    end

    def >=(other)
      cmp = self <=> other
      cmp && cmp >= 0
    end

    private

    def register_python_type_mapping
      PyCall::Conversion.register_python_type_mapping(__pyptr__, self)
    end
  end

  module_function

  class WrapperClassCache < WrapperObjectCache
    def initialize
      types = [LibPython::API::PyType_Type]
      types << LibPython::API::PyClass_Type if defined? LibPython::API::PyClass_Type
      super(*types)
    end

    def check_wrapper_object(wrapper_object)
      unless wrapper_object.kind_of?(Class) && wrapper_object.kind_of?(PyTypeObjectWrapper)
        raise TypeError, "unexpected type #{wrapper_object.class} (expected Class extended by PyTypeObjectWrapper)"
      end
    end

    def self.instance
      @instance ||= self.new
    end
  end

  private_constant :WrapperClassCache

  def wrap_class(pytypeptr)
    check_isclass(pytypeptr)
    WrapperClassCache.instance.lookup(pytypeptr) do
      Class.new do |cls|
        cls.instance_variable_set(:@__pyptr__, pytypeptr)
        cls.extend PyTypeObjectWrapper
      end
    end
  end
end
