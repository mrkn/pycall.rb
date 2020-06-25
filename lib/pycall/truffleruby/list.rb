module PyCall
  class List < Tuple
    include Enumerable

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
  end
end
