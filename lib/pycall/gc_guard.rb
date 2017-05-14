require 'pycall'

module PyCall
  module GCGuard
    @gc_guard = {}

    def self.register(pyobj, obj)
      @gc_guard[pyobj] ||= []
      @gc_guard[pyobj] << obj
    end

    def self.unregister(pyobj)
      @gc_guard.delete pyobj
    end
  end

  private_constant :GCGuard
end
