module PyCall
  class Slice < PyObjectWrapper

    def initialize(*args)
      @__pyptr__ = PyCall.builtins.slice.new(*PyObjectWrapper.unwrap(args)).__pyptr__
    end

    def self.all
      super PyCall.builtins.slice.new(nil)
      #new(PyCall.builtins.slice(0, 10, 1))  # todo fill slice (select all)
    end
  end
end
