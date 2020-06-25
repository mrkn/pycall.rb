module PyCall
  class Tuple < PyObjectWrapper
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

    def to_a
      Array.new(length) {|i| self[i] }
    end

    alias to_ary to_a
  end
end