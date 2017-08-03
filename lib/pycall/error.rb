module PyCall
  class Error < StandardError
  end

  class PythonNotFound < Error
  end

  class LibPythonFunctionNotFound < Error
  end
end
