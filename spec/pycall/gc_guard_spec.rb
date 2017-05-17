require 'spec_helper'

module PyCall
  RSpec.describe GCGuard do
    let(:pyobj) { PyCall.eval('object()') }

    it 'guards Ruby object from GC during the corresponding Python object is registered' do
      obj = Object.new
      GCGuard.register(pyobj, obj)
      expect(GCGuard.guarded_object_count).to eq(1)

      obj_id = obj.object_id
      obj = nil
      GC.start
      expect { ObjectSpace._id2ref(obj_id) }.not_to raise_error

      GCGuard.unregister(pyobj)
      expect(GCGuard.guarded_object_count).to eq(0)

      GC.start
      expect { ObjectSpace._id2ref(obj_id) }.to raise_error(RangeError)
    end

    describe '.register' do
      it 'raises TypeError when a given key is not Python object' do
        expect {
          GCGuard.register(Object.new, Object.new)
        }.to raise_error(TypeError)
      end
    end

    describe '.unregister' do
      it 'does not raise error when non-registered object is given' do
        expect { GCGuard.unregister(pyobj) }.not_to raise_error
      end

      it 'raises TypeError when a given key is not Python object' do
        expect {
          GCGuard.unregister(Object.new)
        }.to raise_error(TypeError)
      end

      it 'uses the object pointers for the equality of Python objects' do
        obj = Object.new
        GCGuard.register(pyobj, obj)
        expect(GCGuard.guarded_object_count).to eq(1)

        GCGuard.unregister(LibPython::PyObjectStruct.new(pyobj.__pyobj__.pointer))
        expect(GCGuard.guarded_object_count).to eq(0)

        obj_id = obj.object_id
        obj = nil
        GC.start
        expect { ObjectSpace._id2ref(obj_id) }.to raise_error(RangeError)
      end
    end

    describe '.embed' do
      before do
        PyCall.eval(<<PYTHON, input_type: :file)
class Obj:
  pass
PYTHON
      end

      after do
        PyCall.eval('del Obj', input_type: :file)
      end

      it 'guards a ruby object during the corresponding Python object is alive' do
        pyptr = PyCall.eval('Obj()').__pyobj__
        obj = Object.new
        obj_id = obj.object_id

        # NOTE: DO NOT USE THE FOLLOWING FORM.
        #
        #     expect { GCGuard.embed(pyptr, obj) }.to change { GCGuard.guarded_object_count }.by(1)
        #
        # This form holds the reference of the value of `obj`.
        # It makes the last expectation in this example to be failed.
        before_count = GCGuard.guarded_object_count
        GCGuard.embed(pyptr, obj)
        expect(GCGuard.guarded_object_count).to eq(before_count + 1)

        obj_id = obj.object_id
        obj = nil
        GC.start
        expect { ObjectSpace._id2ref(obj_id) }.not_to raise_error

        expect {
          PyCall::LibPython.Py_DecRef(pyptr)
        }.to change {
          GCGuard.guarded_object_count
        }.by(-1)

        GC.start
        expect { ObjectSpace._id2ref(obj_id) }.to raise_error(RangeError)
      end
    end
  end
end
