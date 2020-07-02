module PyCall
  module LibPython
    module Finder
    end

    module Helpers
      def self.unicode_literals?
        nil
      end
    end

    module API
    end

    const_set(:PYTHON_VERSION, Polyglot.eval('python', 'import sys;sys.version.split(" ")[0]'))
    const_set(:PYTHON_DESCRIPTION, Polyglot.eval('python', 'import sys;sys.version'))
  end

end