module PyCall
  class Dict < PyObjectWrapper
    include Enumerable

    def self.new(h)
      super(h, {})
    end

    def length
      PyCall.len(self)
    end

    def has_key?(key)
      begin
        __pyptr__.__getitem__(key)
        return true
      rescue => e
        return false
      end
    end

    alias include? has_key?
    alias key? has_key?
    alias member? has_key?

    def [](key)
      @__pyptr__.__getitem__(key)
    end

    def delete(key)
      @__pyptr__.pop(key)
    end

    # todo
    def each(&block)
      PyCall.builtins.list(@__pyptr__.items()) do | tuple |
        block.call(tuple)
      end
    end

    # todo? whats this even?
    def to_h
      inject({}) do |h, (k, v)|
        h.update(k => v)
      end
    end
  end
end
