module PyCall
  List = builtins.list
  class List
    register_python_type_mapping

    include Enumerable

    def include?(item)
      LibPython::Helpers.sequence_contains(__pyptr__, item)
    end

    def length
      PyCall.len(self)
    end

    def each(&block)
      return enum_for unless block_given?
      LibPython::Helpers.sequence_each(__pyptr__, &block)
      self
    end

    def <<(item)
      append(item)
    end

    def push(*items)
      items.each {|i| append(i) }
    end

    def sort
      dup.sort!
    end

    def sort!
      LibPython::Helpers.getattr(__pyptr__, :sort).__call__
      self
    end

    def to_a
      Array.new(length) {|i| self[i] }
    end

    alias to_ary to_a
  end
end
