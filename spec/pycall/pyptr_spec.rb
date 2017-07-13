require 'spec_helper'

module PyCall
  ::RSpec.describe PyPtr do
    describe '.incref' do
      it 'does not raise error for NULL' do
        expect { PyPtr.incref(PyPtr::NULL) }.not_to raise_error
      end
    end

    describe '.decref' do
      it 'does not raise error for NULL' do
        expect { PyPtr.decref(PyPtr::NULL) }.not_to raise_error
      end
    end

    describe '.sizeof' do
      it 'returns nil for NULL' do
        expect(PyPtr.sizeof(PyPtr::NULL)).to eq(nil)
      end

      it 'does not raise error for NULL' do
        expect { PyPtr.sizeof(PyPtr::NULL) }.not_to raise_error
      end
    end

    describe '#null?' do
      it 'returns true for NULL' do
        expect(PyPtr::NULL.null?).to eq(true)
      end

      it 'returns false for None' do
        expect(PyPtr::None.null?).to eq(false)
      end
    end

    describe '#none?' do
      it 'returns true for None' do
        expect(PyPtr::None.none?).to eq(true)
      end

      it 'returns false for NULL' do
        expect(PyPtr::NULL.none?).to eq(false)
      end
    end

    describe '#__ob_type__' do
      it 'returns a PyPtr for None' do
        expect(PyPtr::None.__ob_type__).to be_a(PyPtr)
      end
    end

    describe '#kind_of?' do
      it 'works normally for Ruby class objects' do
        expect(PyPtr::None.kind_of?(PyPtr)).to eq(true)
        expect(PyPtr::None.kind_of?(Object)).to eq(true)
        expect(PyPtr::None.kind_of?(Array)).to eq(false)
        expect { PyPtr::None.kind_of?(Object.new) }.to raise_error(TypeError)
      end

      it 'works for Python type objects' do
        pytype_type = PyPtr.incref(PyPtr.new(LibPython.PyType_Type.to_ptr.address))
        pylong_type = PyPtr.incref(PyPtr.new(LibPython.PyLong_Type.to_ptr.address))

        expect(pylong_type.kind_of?(pytype_type)).to eq(true)
        expect(pylong_type.kind_of?(pylong_type)).to eq(false)

        expect { PyPtr::None.kind_of?(PyPtr::None) }.to raise_error(TypeError)
      end
    end
  end
end
