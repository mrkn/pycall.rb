require 'spec_helper'

module PyCall
  describe Conversions do
    shared_context 'Save original python type map' do
      around do |example|
        begin
          original = Conversions.instance_variable_get(:@python_type_map)
          Conversions.instance_variable_set(:@python_type_map, original.dup)
          example.run
        ensure
          Conversions.instance_variable_set(:@python_type_map, original)
        end
      end
    end

    describe '.python_type_mapping' do
      include_context 'Save original python type map'

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
      include_context 'Save original python type map'

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
