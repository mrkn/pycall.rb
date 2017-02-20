module PyCall
  class Slice
    include PyObjectWrapper

    def self.new(*args)
      start, stop, step = nil
      case args.length
      when 1
        stop = args[0]
        return super(stop) if stop.kind_of?(PyObject)
      when 2
        start, stop = args
      when 3
        start, stop, step = args
      else
        much_or_few = args.length > 3 ? 'much' : 'few'
        raise ArgumentError, "too #{much_or_few} arguments (#{args.length} for 1..3)"
      end
      start = start ? Conversions.from_ruby(start) : PyObject.null
      stop = stop ? Conversions.from_ruby(stop) : PyObject.null
      step = step ? Conversions.from_ruby(step) : PyObject.null
      pyobj = LibPython.PySlice_New(start, stop, step)
      return pyobj.to_ruby unless pyobj.null?
      raise PyError.fetch
    end
  end
end
