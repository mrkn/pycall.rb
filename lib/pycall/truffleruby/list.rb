require "pycall/truffleruby/pyenum"

module PyCall
  class List < PyEnumerable
    include Enumerable

    def initialize(foreign)
      if Truffle::Interop.foreign?(foreign)
        super foreign
      else
        super PyCall.builtins.list.new
        foreign.each do | el |
          self << el
        end
      end
    end

    def <<(item)
      @__pyptr__.append(item)
    end

    # todo ?
    def push(*items)
      items.each {|i| self << (i) }
    end

    def sort
      sort!
    end

    def sort!
      @__pyptr__.sort
    end
  end
end
