module PyCall
  class PyRubyPtr
    attr_reader :__ruby_object__
    def initialize(ruby_object)
      @__ruby_object__ = ruby_object
    end
  end
end
