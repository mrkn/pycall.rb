module PyCall
  class TypeObject
    include PyObjectWrapper

    def to_s
      return "pytype(#{__pyobj__.__name__})"
    end

    alias inspect to_s
  end
end
