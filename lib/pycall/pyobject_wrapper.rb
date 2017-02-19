module PyCall
  module PyObjectWrapper
    def initialize(pyobj, pytype)
      check_type pyobj, pytype
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

    def method_missing(name, *args, **kwargs)
      if PyCall.hasattr?(__pyobj__, name.to_s)
        PyCall.getattr(__pyobj__, name)
      else
        super
      end
    end

    private

    def check_type(pyobj, pytype)
      return if pyobj.kind_of?(PyObject) && pyobj.kind_of?(pytype)
      raise TypeError, "the argument must be a PyObject of #{pytype}"
    end
  end
end
