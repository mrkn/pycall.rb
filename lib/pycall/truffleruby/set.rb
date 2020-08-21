module PyCall
  class Set < PyObjectWrapper

    def initialize(*args)
      super PyCall.builtins.set.new(*args).__pyptr__ #TODO: do without wrap->unwrap->wrap
    end

    def size
      @__pyptr__.__len__
    end

    alias length size

    def include?(obj)
      @__pyptr__.__contains__(obj)
    end
  end

  Conversion.register_python_type_mapping(Set.new().__pyptr__, Set)
end
