require 'pycall'

module PyCall
  module GCGuard
    @gc_guard = {}

    def self.register(pyobj, obj)
      pyobj = check_pyobj(pyobj)
      @gc_guard[pyobj] ||= []
      @gc_guard[pyobj] << obj
    end

    def self.unregister(pyobj)
      pyobj = check_pyobj(pyobj)
      @gc_guard.delete pyobj
    end

    def self.guarded_object_count
      @gc_guard.length
    end

    def self.check_pyobj(pyobj)
      pyobj = pyobj.__pyobj__ if pyobj.respond_to? :__pyobj__
      return pyobj if pyobj.kind_of? LibPython::PyObjectStruct
      raise TypeError, "The argument must be a Python object"
    end
  end

  private_constant :GCGuard
end
