module PyCall
  class Dict
    def initialize(pyobj)
      @pyobj = pyobj
    end

    def [](key)
      key = key.to_s if key.is_a? Symbol
      py_obj_ptr = if key.is_a? String
                     LibPython.PyDict_GetItemString(__pyobj__, key)
                   else
                     LibPython.PyDict_GetItem(__pyobj__, key)
                   end
      return nil if py_obj_ptr.null?
      __convert__ py_obj_ptr
    end

    def []=(key, value)
      key = key.to_s if key.is_a? Symbol
      if key.is_a? String
        __convert__ LibPython.PyDict_SetItemString(__pyobj__, key, value)
      else
        __convert__ LibPython.PyDict_SetItem(__pyobj__, key, value)
      end
      value
    end

    def delete(key)
      key = key.to_s if key.is_a? Symbol
      if key.is_a? String
        value = LibPython.PyDict_GetItemString(__pyobj__, key)
        __convert__ LibPython.PyDict_DelItemString(__pyobj__, key)
      else
        value = LibPython.PyDict_GetItem(__pyobj__, key)
        __convert__ LibPython.PyDict_DelItem(__pyobj__, key)
      end
      value
    end

    def size
      __convert__ LibPython.PyDict_Size(__pyobj__)
    end

    def keys
      __convert__ LibPython.PyDict_Keys(__pyobj__)
    end

    def values
      __convert__ LibPython.PyDict_Values(__pyobj__)
    end

    def has_key?(key)
      1 == (__convert__ LibPython.PyDict_Contains(__pyobj__, key))
    end

    def default=(val)
      # TODO: PYDict_SetDefault
    end

    def dup
      # TODO: PyDict_Copy
    end

    def to_a
      LibPython.PyDict_Items(__pyobj__)
    end

    def to_hash
      # TODO: PyDict_Next
    end

    private

    def __pyobj__
      @pyobj
    end

    def __convert__(py_obj_ptr)
      Conversions.convert(py_obj_ptr)
    end
  end
end
