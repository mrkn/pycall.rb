module PyCall
  class List < PyObjectWrapper
    include Enumerable

    def include?(item)
      @__foreignobj__.contains(item)
    end

    def length
      PyCall.len(self)
    end

    # todo
    def each(&block)
      return enum_for unless block_given?
      LibPython::Helpers.sequence_each(__pyptr__, &block)
      self
    end

    def <<(item)
      @__foreignobj__.append(item)
    end

    # todo ?
    def push(*items)
      items.each {|i| self << (i) }
    end

    def sort
      sort!
    end

    def sort!
      @__foreignobj__.sort
    end

    def to_a
      Array.new(length) {|i| self[i] }
    end

    alias to_ary to_a
  end
end
