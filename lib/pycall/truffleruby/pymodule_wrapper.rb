module PyCall

  class PyModuleWrapper < PyObjectWrapper
    def [](*args)
      case args[0]
      when String, Symbol
        PyCall.getattr(self, args[0])
      else
        super
      end
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
    if check_ismodule(pymodptr)
      super.class.wrap(pymodptr)
    end
  end

end
