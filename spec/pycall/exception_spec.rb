require 'spec_helper'

RSpec.describe PyCall do
  describe '.raise_python_exception' do
    specify do
      begin
        raise TypeError, 'type error in ruby'
      rescue => error
        PyCall.raise_python_exception(error)
      end
      pyerr = PyCall::PyError.fetch
      expect(pyerr.type).to eq(PyCall::LibPython.PyExc_TypeError)
      expect(pyerr.message).to match(/\btype error in ruby\b/)
    end
  end
end
