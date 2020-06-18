module PyCall
  class Set
    include PyObjectWrapper

    def initialize(pyobj)
      super(pyobj)
    end

    def size
      LibPython.PySet_Size(__pyobj__)
    end

    alias length size

    def include?(obj)
      1 == LibPython.PySet_Contains(__pyobj__, Conversions.from_ruby(obj))
    end
  end
end
