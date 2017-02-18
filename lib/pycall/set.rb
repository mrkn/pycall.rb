module PyCall
  class Set
    include PyObjectWrapper

    def initialize(pyobj)
      super(pyobj, LibPython.PySet_Type)
    end

    def length
      LibPython.PySet_Size(__pyobj__)
    end

    def include?(obj)
      1 == LibPython.PySet_Contains(__pyobj__, Conversions.from_ruby(obj))
    end
  end
end
