module PyCall
  class Slice < PyObjectWrapper
    def initialize(foreign)
      if foreign.nil?
        super PyCall.builtins.slice(nil)
      else
        super foreign
      end
    end
    def self.all
      new(PyCall.builtins.slice(0, 10, 1))  # todo fill slice (select all)
    end
  end
end
