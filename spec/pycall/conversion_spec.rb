require 'spec_helper'

module PyCall
  describe Conversions do
    describe '.from_ruby' do
      def from_ruby(obj)
        Conversions.from_ruby(obj)
      end

      context 'for true' do
        subject { from_ruby(true) }
        it { is_expected.to be_kind_of(LibPython.PyBool_Type) }
        specify { expect(subject.to_ruby).to equal(true) }
      end

      context 'for false' do
        subject { from_ruby(false) }
        it { is_expected.to be_kind_of(LibPython.PyBool_Type) }
        specify { expect(subject.to_ruby).to equal(false) }
      end

      [-1, 0, 1].each do |int_value|
        context "for #{int_value}" do
          subject { from_ruby(int_value) }
          it { is_expected.to be_kind_of(LibPython.PyInt_Type) }
          specify { expect(subject.to_ruby).to eq(int_value) }
        end
      end

      [-Float::INFINITY, -1.0, 0.0, 1.0, Float::INFINITY, Float::NAN].each do |float_value|
        context "for #{float_value}" do
          subject { from_ruby(float_value) }
          it { is_expected.to be_kind_of(LibPython.PyFloat_Type) }
          if float_value.nan?
            specify { expect(subject.to_ruby).to be_nan }
          else
            specify { expect(subject.to_ruby).to eq(float_value) }
          end
        end
      end
    end
  end
end
