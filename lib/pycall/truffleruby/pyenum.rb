module PyCall
  class PyEnumerable < PyObjectWrapper
    include Enumerable

    def initialize(foreign)
      super foreign
    end

    def include?(item)
      @__pyptr__.__contains__(item)
    end

    def length
      PyCall.len(self)
    end

    # todo
    def each(&block)
      return enum_for unless block_given?
      iterator = Polyglot.eval('python', 'iter').call(__pyptr__)
      while true
        begin
          item = Polyglot.eval('python', 'next').call(iterator)
        rescue#StopIteration Exception from Python
          break
        end
        block.call(item)
      end
      self
    end

    def to_a
      Array.new(length) {|i| self[i] }
    end

    alias to_ary to_a
  end
end