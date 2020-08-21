module PyCall
  class Dict < PyObjectWrapper
    include Enumerable

    def initialize(*args, **kwargs)
      if args.first.kind_of?(Hash)
        super(build_dict(args.first))
      else
        if kwargs.empty?
          super Polyglot.eval('python', 'dict').call()
        else
          super(build_dict(kwargs))
        end
      end
    end

    def build_dict(kwargs)
      dict = Polyglot.eval('python', 'dict').call()
      kwargs.each do |key, value|
        dict.__setitem__(key, value)
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

    def each(&block)
      return enum_for unless block_given?
      iterator = Polyglot.eval('python', 'iter').call(__pyptr__)
      while true
        begin
          item = Polyglot.eval('python', 'next').call(iterator)
        rescue#StopIteration Exception from Python
          break
        end
        block.call(item, self[item])
      end
      self
    end

    def to_h
      inject({}) do |h, (k, v)|
        h.update(k => v)
      end
    end

    def kind_of?(cls)
      case
      when cls == PyCall::LibPython::API::PyDict_Type
        true
      else
        super
      end
    end
  end

  Conversion.register_python_type_mapping(Dict.new().__pyptr__, Dict)
end
