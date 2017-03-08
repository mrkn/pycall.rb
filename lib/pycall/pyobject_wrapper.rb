module PyCall
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

    def initialize(pyobj, pytype=nil)
      check_type pyobj, pytype
      pytype ||= LibPython.PyObject_Type(pyobj)
      @__pyobj__ = pyobj
    end

    attr_reader :__pyobj__

    def ==(other)
      case other
      when self.class
        __pyobj__ == other.__pyobj__
      when PyObject
        __pyobj__ == other
      else
        super
      end
    end

    def call(*args, **kwargs)
      __pyobj__.call(*args, **kwargs)
    end

    def method_missing(name, *args, **kwargs)
      if PyCall.hasattr?(__pyobj__, name.to_s)
        PyCall.getattr(__pyobj__, name)
      else
        super
      end
    end

    def to_s
      __pyobj__.to_s
    end

    def inspect
      __pyobj__.inspect
    end

    private

    def check_type(pyobj, pytype)
      return if pyobj.kind_of?(PyObject)
      return if pytype.nil? || pyobj.kind_of?(pytype)
      raise TypeError, "the argument must be a PyObject of #{pytype}"
    end
  end
end
