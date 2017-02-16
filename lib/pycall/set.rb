module PyCall
  class Set
    def initialize(pyobj)
      @__pyobj__ = pyobj
    end

    def length
      LibPython.PySet_Size(__pyobj__)
    end

    def include?(obj)
      1 == LibPython.PySet_Contains(__pyobj__, Conversions.from_ruby(obj))
    end

    private

    attr_reader :__pyobj__
  end
end
