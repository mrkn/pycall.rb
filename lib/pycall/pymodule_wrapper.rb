require 'pycall/pyobject_wrapper'

module PyCall
  module PyModuleWrapper
    include PyObjectWrapper

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
    check_ismodule(pymodptr)
    WrapperModuleCache.instance.lookup(pymodptr) do
      Module.new do |mod|
        mod.instance_variable_set(:@__pyptr__, pymodptr)
        mod.extend PyModuleWrapper
      end
    end
  end
end
