module PyCall
  class Set < PyObjectWrapper

    def size
      @__pyptr__.__len__
    end

    alias length size

    def include?(obj)
      @__pyptr__.__contains__(obj)
    end
  end
end
