require 'pycall/error'

module PyCall
  class PyError < Error
    def initialize(type, value, traceback)
      @type = type
      @value = value
      @traceback = traceback
      super("Exception occurred in Python")
    end

    attr_reader :type, :value, :traceback

    def to_s
      "#{type}: #{value}".tap do |msg|
        if (strs = format_traceback)
          msg << "\n"
          strs.each {|s| msg << s }
        end
      end
    end

    private

    def format_traceback
      return nil if traceback.nil?
      ::PyCall.import_module('traceback').format_tb(traceback)
    end
  end
end
