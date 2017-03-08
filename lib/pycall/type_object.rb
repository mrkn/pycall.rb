module PyCall
  class TypeObject
    include PyObjectWrapper

    def to_s
      return "pytype(#{self.__name__})"
    end

    alias inspect to_s
  end
end
