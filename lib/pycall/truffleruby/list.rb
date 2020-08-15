require "pycall/truffleruby/pyenum"

module PyCall
  class List < PyEnumerable
    include Enumerable

    def initialize(foreign)
      if Truffle::Interop.foreign?(foreign)
        super foreign
      else
        super PyCall.builtins.list.new.__pyptr__
        foreign.each do | el |
          self << el
        end
      end
    end

    def [](*key)
      if key.first.is_a?(PyObjectWrapper)
        PyObjectWrapper.wrap(@__pyptr__.__getitem__(key.first.__pyptr__))
      else
        begin
          PyObjectWrapper.wrap(@__pyptr__.__getitem__(key.first))
        rescue => e
          nil
        end
      end
    end

    def []=(*key, value)
      @__pyptr__.__setitem__(key.first, value)
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



      puts @__pyptr__
      puts @__pyptr__.class
      list = PyCall.copy.deepcopy(@__pyptr__)
      list.sort
      puts list
      List.new(list)
    end

    def to_a
      Array.new (length) {|i| self[i]}
    end
  end

  Conversion.register_python_type_mapping(List.new([]).__pyptr__, List.class)
end
