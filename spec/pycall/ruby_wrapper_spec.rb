require 'spec_helper'

RSpec.describe PyCall do
  describe '.wrap_ruby_object' do
    let!(:guarded_object_count_origin) { PyCall.const_get(:GCGuard).guarded_object_count }

    it 'registers the wrapped ruby object into GCGuard table' do
      obj = Object.new
      wrapped = PyCall.wrap_ruby_object(obj)
      expect(PyCall.const_get(:GCGuard).guarded_object_count).to eq(guarded_object_count_origin + 1)

      obj_id, obj = obj.object_id, nil
      GC.start
      expect{ ObjectSpace._id2ref(obj_id) }.not_to raise_error

      PyCall::LibPython.Py_DecRef(wrapped)
      wrapped = nil
      expect(PyCall.const_get(:GCGuard).guarded_object_count).to eq(guarded_object_count_origin + 0)

      # TODO: I want to ensure the obj should be collected by the following
      #       GC.start, but it's sometimes not collected, so currently the
      #       following example is need to be disabled.
      # NOTE: The problem here may be occurred only on 32-bit Ruby on Windows.
      # GC.start
      # expect{ ObjectSpace._id2ref(obj_id) }.to raise_error(RangeError)
    end
  end

  describe '.wrap_ruby_callable' do
    specify do
      expect { |b|
        PyCall.eval(<<PYTHON, input_type: :file)
def call_function(f, x):
  return f(str(x))
PYTHON
        begin
          f = PyCall.wrap_ruby_callable(b.to_proc)
          PyCall.eval('call_function').(f, 42)
        ensure
          PyCall::LibPython.Py_DecRef(f)
          f = nil
        end
      }.to yield_with_args('42')
    end
  end
end
