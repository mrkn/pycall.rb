module PyCall
  class Set
    def initialize(pyobj)
      @__pyobj__ = pyobj
    end

    def length
      LibPython.PySet_Size(__pyobj__)
    end

    def include?(obj)
      # TODO: PySet_Contains
      false
    end

    private

    attr_reader :__pyobj__
  end
end
