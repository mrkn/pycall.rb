module PyCall
  class Dict
    def initialize(pyobj)
      @pyobj = pyobj
    end

    def [](key)
      key = key.to_s if key.is_a? Symbol
      if key.is_a? String
        LibPython.PyDict_GetItemString(__pyobj__, key).to_ruby
      else
        LibPython.PyDict_GetItem(__pyobj__, key).to_ruby
      end
    end

    def []=(key, value)
      key = key.to_s if key.is_a? Symbol
      if key.is_a? String
        LibPython.PyDict_SetItemString(__pyobj__, key, value).to_ruby
      else
        LibPython.PyDict_SetItem(__pyobj__, key, value).to_ruby
      end
      value
    end

    def delete(key)
      key = key.to_s if key.is_a? Symbol
      if key.is_a? String
        value = LibPython.PyDict_GetItemString(__pyobj__, key).to_ruby
        LibPython.PyDict_DelItemString(__pyobj__, key)
      else
        value = LibPython.PyDict_GetItem(__pyobj__, key).to_ruby
        LibPython.PyDict_DelItem(__pyobj__, key)
      end
      value
    end

    def size
      LibPython.PyDict_Size(__pyobj__)
    end

    def keys
      LibPython.PyDict_Keys(__pyobj__).to_ruby
    end

    def values
      LibPython.PyDict_Values(__pyobj__).to_ruby
    end

    def has_key?(key)
      1 == LibPython.PyDict_Contains(__pyobj__, key).to_ruby
    end

    def default=(val)
      # TODO: PYDict_SetDefault
    end

    def dup
      # TODO: PyDict_Copy
    end

    def to_a
      LibPython.PyDict_Items(__pyobj__).to_ruby
    end

    def to_hash
      # TODO: PyDict_Next
    end

    private

    def __pyobj__
      @pyobj
    end
  end
end
