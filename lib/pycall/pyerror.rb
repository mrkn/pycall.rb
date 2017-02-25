module PyCall
  class PyError < StandardError
    def self.fetch
      ptrs = FFI::MemoryPointer.new(:pointer, 3)
      ptype      = ptrs + 0 * ptrs.type_size
      pvalue     = ptrs + 1 * ptrs.type_size
      ptraceback = ptrs + 2 * ptrs.type_size
      LibPython.PyErr_Fetch(ptype, pvalue, ptraceback)
      LibPython.PyErr_NormalizeException(ptype, pvalue, ptraceback)
      type = PyTypeObject.new(ptype.read(:pointer))
      value = PyObject.new(pvalue.read(:pointer))
      traceback = PyObject.new(ptraceback.read(:pointer))
      new(type, value, traceback)
    end

    def initialize(type, value, traceback)
      @type = type
      @value = value
      @traceback = traceback
      super("Error occurred in Python")
    end

    attr_reader :type, :value, :traceback

    def message
      "#{PyObject.new(type.to_ptr)}: #{value}".tap do |msg|
        unless traceback.null?
          if (o = PyCall.format_traceback(traceback))
            msg.concat("\n", *o)
          end
        end
      end
    end
  end
end
