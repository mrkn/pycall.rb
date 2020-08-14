require "pycall/truffleruby/pyenum"

module PyCall
  class Tuple < PyEnumerable

    def initialize(*args)
      super PyCall.builtins.tuple.new(args).__pyptr__#TODO: do without wrap->unwrap->wrap
    end

    def is_a?(class1)
      if class1 == PyCall.tuple
        true
      else
        super.is_a?(class1)
      end
    end
  end
end