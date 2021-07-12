module PyCall
  class IterableWrapper
    include Enumerable

    def initialize(obj)
      @obj = check_iterable(obj)
    end

    private def check_iterable(obj)
      unless PyCall.hasattr?(obj, :__iter__)
        raise ArgumentError, "%p object is not iterable" % obj
      end
      obj
    end

    def each
      return enum_for(__method__) unless block_given?
      iter = @obj.__iter__()
      while true
        begin
          yield iter.__next__()
        rescue PyCall::PyError => err
          if err.type == PyCall.builtins.StopIteration
            break
          else
            raise err
          end
        end
      end
    end
  end
end
