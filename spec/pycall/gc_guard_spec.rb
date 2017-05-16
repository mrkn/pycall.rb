require 'spec_helper'

module PyCall
  RSpec.describe GCGuard do
    let(:pyobj) { PyCall.eval('object()') }

    it 'guards Ruby object from GC during the corresponding Python object is registered' do
      obj = Object.new
      obj_id = obj.object_id
      GCGuard.register(pyobj, obj)
      expect(GCGuard.guarded_object_count).to eq(1)

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
    end
  end
end
