require "pycall/truffleruby/pyenum"

module PyCall
  class Tuple < PyEnumerable

    def initialize(*args)
      if Truffle::Interop.foreign?(args.first)
        super args.first
      else
        super PyCall.builtins.tuple.new(args).__pyptr__ #TODO: do without wrap->unwrap->wrap
      end
    end

    def is_a?(class1)
      if class1 == PyCall.tuple
        true
      else
        super.is_a?(class1)
      end
    end
  end

  PyCall::Conversion.register_python_type_mapping(Tuple.new().__pyptr__, Tuple.class)
end