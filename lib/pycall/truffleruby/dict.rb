module PyCall
  class Dict < PyObjectWrapper
    include Enumerable

    def initialize(*args, **kwargs)
      if args.first.kind_of?(Hash)
        super(build_dict(args.first))
      else
        if kwargs.empty?
          super PyCall.builtins.dict()
        else
          super(build_dict(kwargs))
        end
      end
    end

    def build_dict(kwargs)
      dict = PyCall.builtins.dict()
      kwargs.each do |key, value|
        dict[key] = value
      end
      dict
    end

    def length
      @__pyptr__.__len__()
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
      begin
        @__pyptr__.__getitem__(key)
      rescue => e
        nil
      end
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
