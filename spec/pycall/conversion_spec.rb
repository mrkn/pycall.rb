require 'spec_helper'

module PyCall
  ::RSpec.describe Conversions do
    describe 'for object()' do
      specify { expect(PyCall.eval('object()')).to be_kind_of(PyObject) }
    end

    describe '.python_type_mapping' do
      include_context 'Save and restore original python type map'

      it 'adds type map between python type and ruby type' do
        array_module = PyCall.import_module('array')
        expect {
          Conversions.python_type_mapping(array_module.array, Array)
        }.to change {
          Conversions.instance_variable_get(:@python_type_map).length
        }.from(0).to(1)
      end
    end

    describe '.to_ruby' do
      include_context 'Save and restore original python type map'

      let(:fractions_module) do
        PyCall.import_module('fractions')
      end

      let(:fraction_class) do
        PyCall.getattr(fractions_module, :Fraction)
      end

      let(:fraction_value) do
        fraction_class.(355, 113)
      end

      context 'the given python type is not registered in type mapping' do
        before do
          Conversions.instance_variable_get(:@python_type_map).delete_if do |type_pair|
            type_pair.pytype == fraction_class
          end
        end

        it 'does not convert the given python object' do
          expect(Conversions.to_ruby(fraction_value)).to be_kind_of(PyObject)
        end
      end

      context 'the given python type is registered in type mapping' do
        before do
          fraction_value # NOTE: this line should be evaluated before the following line to prevent conversion
          Conversions.python_type_mapping(fraction_class, ->(pyobj) { Rational(pyobj.numerator, pyobj.denominator) })
        end

        it 'converts the given python object to the specific ruby object' do
          expect(Conversions.to_ruby(fraction_value)).to eq(Rational(355, 113))
        end
      end
    end

    describe '.from_ruby' do
      def from_ruby(obj)
        Conversions.from_ruby(obj)
      end

      context 'for a PyObjectStruct' do
        let(:pyobj) { PyCall.eval('object()') }
        subject { from_ruby(pyobj.__pyobj__) }
        it { is_expected.to equal(pyobj.__pyobj__) }
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

      context 'for a Hash' do
        let(:hash) { { a: 1, b: 2, c: 3 } }
        subject { from_ruby(hash) }
        it { is_expected.to be_kind_of(LibPython.PyDict_Type) }
        specify { expect(Conversions.to_ruby(subject)).to eq(hash) }
      end

      context 'for :ascii_symbol' do
        subject { from_ruby(:ascii_symbol) }
        if PyCall.unicode_literals?
          it { is_expected.to be_kind_of(LibPython.PyUnicode_Type) }
        else
          it { is_expected.to be_kind_of(LibPython.PyString_Type) }
        end
      end

      context 'for :マルチバイトシンボル' do
        subject { from_ruby(:マルチバイトシンボル) }
        it { is_expected.to be_kind_of(LibPython.PyUnicode_Type) }
      end

      context 'for an ascii string' do
        subject { from_ruby('ascii string') }
        if PyCall.unicode_literals?
          it { is_expected.to be_kind_of(LibPython.PyUnicode_Type) }
        else
          it { is_expected.to be_kind_of(LibPython.PyString_Type) }
        end
      end

      context 'for a unicode string' do
        subject { from_ruby('ユニコード') }
        it { is_expected.to be_kind_of(LibPython.PyUnicode_Type) }
      end

      context 'for a binary string' do
        subject { from_ruby("binary string".force_encoding(Encoding::BINARY)) }
        it { is_expected.to be_kind_of(LibPython.PyString_Type) }
      end

      context 'for a Proc object' do
        let(:proc_object) { ->() {} }
        subject { from_ruby(proc_object) }
        it { is_expected.to be_kind_of(RubyWrapStruct) }
      end
    end
  end
end
