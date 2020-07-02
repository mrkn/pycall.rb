module PyCall
  class Set < PyObjectWrapper

    def size
      @__foreignobj__.__len__
    end

    alias length size

    def include?(obj)
      @__foreignobj__.__contains__(obj)
    end
  end
end
