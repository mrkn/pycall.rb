module PyCall
  class Dict
    def self.new(init=nil)
      case init
      when PyObject
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

    def initialize(pyobj)
      check_type pyobj
      @__pyobj__ = pyobj
    end

    attr_reader :__pyobj__

    def ==(other)
      case other
      when Dict
        __pyobj__ == other.__pyobj__
      else
        super
      end
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
      value = Conversions.from_ruby(value)
      if key.is_a? String
        LibPython.PyDict_SetItemString(__pyobj__, key, value)
      else
        LibPython.PyDict_SetItem(__pyobj__, key, value)
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

    def check_type(pyobj)
      return if pyobj.kind_of?(PyObject) && pyobj.kind_of?(LibPython.PyDict_Type)
      raise TypeError, "the argument must be a PyObject of dict"
    end
  end
end
