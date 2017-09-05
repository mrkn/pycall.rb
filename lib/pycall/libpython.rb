module PyCall
  module LibPython
    require 'pycall/libpython/finder'

    def self.handle
      # NOTE: PyCall.init redefine this method.
      #       See pycall/init.rb for the detail.
      PyCall.init
      handle
    end
  end
end
