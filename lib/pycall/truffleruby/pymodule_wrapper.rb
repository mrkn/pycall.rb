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

    def kind_of?(cls)
      if cls == Module
        true
      else
        super
      end
    end
  end

  module_function

  def wrap_module(pymodptr)
    if check_ismodule(pymodptr)
      PyModuleWrapper.new(pymodptr)
    end
  end

end
