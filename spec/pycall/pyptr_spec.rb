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
  end
end
