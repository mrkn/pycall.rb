module PyCall
  Dict = builtins.dict
  class Dict
    register_python_type_mapping

    include Enumerable

    def self.new(h)
      super(h, {})
    end

    def length
      PyCall.len(self)
    end

    def has_key?(key)
      LibPython::Helpers.dict_contains(__pyptr__, key)
    end

    alias include? has_key?
    alias key? has_key?
    alias member? has_key?

    def [](key)
      super
    rescue PyError
      nil
    end

    def delete(key)
      v = self[key]
      LibPython::Helpers.delitem(__pyptr__, key)
      v
    end

    def each(&block)
      return enum_for unless block_given?
      LibPython::Helpers.dict_each(__pyptr__, &block)
      self
    end

    def to_h
      inject({}) do |h, (k, v)|
        h.update(k => v)
      end
    end
  end
end
