require 'pycall/error'

module PyCall
  class PyError < Error
    def initialize(type, value, traceback)
      @type = type
      @value = value
      @traceback = traceback
      super('Exception occurred in Python')
    end

    attr_reader :type, :value, :traceback

    def to_s
      str = "#{type.to_s.gsub("\n", "")}" 
      if value != ""
        str += ": #{value.to_s.gsub("\n", "")}"
      end
      tb = format_traceback
      if tb != ""
        str += "\n" + tb
      end
      str
    end

    private

    def format_traceback
      return '' if traceback.nil?
      return traceback.join("\n") if traceback.kind_of?(Array)
      return ''
    end

    def self.occurred?
      false
    end
  end
end
