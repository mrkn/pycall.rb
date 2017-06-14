module PyCall
  class List
    include PyObjectWrapper
    include Enumerable

    def self.new(init=nil)
      case init
      when LibPython::PyObjectStruct
        super
      when nil
        new(0)
      when Integer
        new(LibPython.PyList_New(init))
      when Array
        new.tap do |list|
          init.each do |item|
            list << item
          end
        end
      else
        new(obj.to_ary)
      end
    end

    def <<(value)
      value = Conversions.from_ruby(value)
      LibPython.PyList_Append(__pyobj__, value)
      self
    end

    def size
      LibPython.PyList_Size(__pyobj__)
    end

    alias length size

    def include?(value)
      value = Conversions.from_ruby(value)
      value = LibPython.PySequence_Contains(__pyobj__, value)
      raise PyError.fetch if value == -1
      1 == value
    end

    def ==(other)
      case other
      when Array
        self.to_a == other
      else
        super
      end
    end

    def each
      return enum_for unless block_given?
      i, n = 0, size
      while i < n
        yield self[i]
        i += 1
      end
      self
    end

    def to_a
      [].tap do |a|
        i, n = 0, size
        while i < n
          a << self[i]
          i += 1
        end
      end
    end

    alias to_ary to_a
  end
end
