module PyCall
  class Dict
    include PyObjectWrapper

    def self.new(init=nil)
      case init
      when LibPython::PyObjectStruct
        super
      when nil
        new(LibPython.PyDict_New())
      when Hash
        new.tap do |dict|
          init.each do |key, value|
            dict[key] = value
          end
        end
      else
        raise TypeError, "the argument must be a PyObject or a Hash"
      end
    end

    def [](key)
      key = key.to_s if key.is_a? Symbol
      key = key.__pyobj__ if key.respond_to?(:__pyobj__)
      value = if key.is_a? String
                LibPython.PyDict_GetItemString(__pyobj__, key).to_ruby
              else
                LibPython.PyDict_GetItem(__pyobj__, key).to_ruby
              end
    ensure
      case value
      when LibPython::PyObjectStruct
        PyCall.incref(value)
      when PyObjectWrapper
        PyCall.incref(value.__pyobj__)
      end
    end

    def []=(key, value)
      key = key.to_s if key.is_a? Symbol
      key = key.__pyobj__ if key.respond_to?(:__pyobj__)
      value = Conversions.from_ruby(value)
      value = value.__pyobj__ unless value.kind_of? LibPython::PyObjectStruct
      if key.is_a? String
        LibPython.PyDict_SetItemString(__pyobj__, key, value)
      else
        LibPython.PyDict_SetItem(__pyobj__, key, value)
      end
      value
    end

    def delete(key)
      key = key.to_s if key.is_a? Symbol
      key = key.__pyobj__ if key.respond_to?(:__pyobj__)
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
      key = Conversions.from_ruby(key)
      value = LibPython.PyDict_Contains(__pyobj__, key)
      raise PyError.fetch if value == -1
      1 == value
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
  end
end
