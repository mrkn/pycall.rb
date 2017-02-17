module PyCall
  class Tuple
    def self.new(init)
      case init
      when Integer
        super(LibPython.PyTuple_New(init))
      when Array
        tuple = new(init.length)
        init.each_with_index do |obj, index|
          tuple[index] = obj
        end
        tuple
      when PyObject
        super(init)
      end
    end

    # Make tuple from array
    def self.[](*ary)
      new(ary)
    end

    def initialize(pyobj)
      check_type pyobj
      @__pyobj__ = pyobj
    end

    attr_reader :__pyobj__

    def ==(other)
      case other
      when Tuple
        __pyobj__ == other.__pyobj__
      else
        super
      end
    end

    def [](index)
      LibPython.PyTuple_GetItem(__pyobj__, index).to_ruby
    end

    def []=(index, value)
      LibPython.PyTuple_SetItem(__pyobj__, index, Conversions.from_ruby(value))
    end

    private

    def check_type(pyobj)
      return if pyobj.kind_of?(PyObject) && pyobj.kind_of?(LibPython.PyTuple_Type)
      raise TypeError, "the argument must be a PyObject of tuple"
    end
  end
end
