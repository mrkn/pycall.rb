module PyCall
  class Slice < PyObjectWrapper
    def self.all
      new(PyCall.builtins.slice(0, 10, 1))  # todo fill slice (select all)
    end
  end
end
