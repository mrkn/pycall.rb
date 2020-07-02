require "pycall/truffleruby/pyenum"

module PyCall
  class Tuple < PyEnumerable

    def initialize(foreign)
      if Truffle::Interop.foreign?(foreign)
        super foreign
      else
        super PyCall.builtins.tuple(*foreign)
      end
    end
  end
end