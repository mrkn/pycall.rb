require 'spec_helper'

module PyCall
  ::RSpec.describe Conversion do
    describe '.register_python_type_mapping' do
      let(:wrapper_class) do
        PyCall.import_module('fractions').Fraction
      end

      let(:python_class) do
        wrapper_class.__pyptr__
      end

      after do
        Conversion.unregister_python_type_mapping(python_class)
      end

      it 'returns true and registers a given type mapping' do
        expect(LibPython::Helpers.call_object(python_class).class).not_to eq(wrapper_class)
        expect(Conversion.register_python_type_mapping(python_class, wrapper_class)).to eq(true)
        expect(LibPython::Helpers.call_object(python_class).class).to eq(wrapper_class)
      end

      context 'when no type mapping for a given Python type is registered' do
        before do
          Conversion.register_python_type_mapping(python_class, wrapper_class)
        end

        it 'returns false' do
          expect(Conversion.register_python_type_mapping(python_class, wrapper_class)).to eq(false)
        end
      end

      context 'when there is a type mapping for a given Python type' do
        context 'when a given Ruby class at the 2nd argument is not a PyCall::PyTypeObjectWrapper' do
          it 'raises TypeError' do
            expect {
              Conversion.register_python_type_mapping(python_class, Class.new)
            }.to raise_error(TypeError, 'ruby class must be extended by PyCall::PyTypeObjectWrapper')
          end
        end

        context 'when the 2nd argument is not a Ruby class' do
          it 'raises TypeError' do
            expect {
              Conversion.register_python_type_mapping(python_class, '42')
            }.to raise_error(TypeError, /wrong argument type String \(expected Class\)/)
          end
        end
      end

      context 'when the 1st argument is not a PyCall::PyTypePtr' do
        it 'raises TypeError' do
          expect {
            Conversion.register_python_type_mapping('42', wrapper_class)
          }.to raise_error(TypeError, /unexpected type String \(expected PyCall::PyTypePtr\)/)
        end
      end
    end

    describe '.unregister_python_type_mapping' do
      let(:wrapper_class) do
        PyCall.import_module('fractions').Fraction
      end

      let(:python_class) do
        wrapper_class.__pyptr__
      end

      it 'returns true and unregisters the type mapping for a given Python type' do
        Conversion.register_python_type_mapping(python_class, wrapper_class)
        expect(Conversion.unregister_python_type_mapping(python_class)).to eq(true)
        expect(LibPython::Helpers.call_object(python_class).class).not_to eq(wrapper_class)
      end

      context 'when the type mapping for a given Python type is not registered' do
        it 'returns false' do
          expect(Conversion.unregister_python_type_mapping(python_class)).to eq(false)
        end
      end

      context 'when the 1st argument is not a PyCall::PyTypePtr' do
        it 'raises TypeError' do
          expect {
            Conversion.unregister_python_type_mapping('42')
          }.to raise_error(TypeError, /unexpected type String \(expected PyCall::PyTypePtr\)/)
        end
      end
    end

    describe '.to_ruby' do
      context 'for a Python type object' do
        let(:pycall_module) { PyCall.import_module('pycall') }
        subject { pycall_module.import_test.Foo }
        it { is_expected.to be_a(Class) }
        it { is_expected.to be_a(PyTypeObjectWrapper) }
      end

      context 'for a Python module object' do
        let(:pycall_module) { PyCall.import_module('pycall') }
        subject { pycall_module.import_test }
        it { is_expected.to be_a(Module) }
        it { is_expected.to be_a(PyObjectWrapper) }
      end

      context 'for a unicode string' do
        let(:ruby_snowman) { "\u{2603}" }
        let(:python_snowman) { Conversion.from_ruby(ruby_snowman) }
        subject { Conversion.to_ruby(python_snowman) }
        it { is_expected.to eq(ruby_snowman) }
      end

      context 'for a large size string' do
        let(:large_string) { 'x' * 10000 }
        subject { Conversion.to_ruby(Conversion.from_ruby(large_string)) }
        it { is_expected.to eq(large_string) }
      end

      describe 'inheritance support' do
        let(:pymod) { PyCall.import_module('pycall.simple_class') }
        let(:simple_class) { pymod.SimpleClass }
        let(:simple_sub_class) { pymod.SimpleSubClass }

        context 'when the super class was registered to python type mapping' do
          before do
            Conversion.register_python_type_mapping(simple_class.__pyptr__, simple_class)
          end

          after do
            Conversion.unregister_python_type_mapping(simple_class.__pyptr__)
          end

          specify do
            expect(simple_class.new).to be_instance_of(simple_class)
            expect(simple_sub_class.new).to be_instance_of(simple_class)
          end

          context 'when the subclass was also registered to python type mapping' do
            before do
              Conversion.register_python_type_mapping(simple_sub_class.__pyptr__, simple_sub_class)
            end

            after do
              Conversion.unregister_python_type_mapping(simple_sub_class.__pyptr__)
            end

            specify do
              expect(simple_class.new).to be_instance_of(simple_class)
              expect(simple_sub_class.new).to be_instance_of(simple_sub_class)
            end
          end
        end
      end
    end

    describe '.from_ruby' do
      xcontext 'for a PyObjectStruct' # TODO

      context 'for true' do
        subject { Conversion.from_ruby(true) }
        it { is_expected.to be_a(LibPython::API::PyBool_Type) }
        specify { expect(Conversion.to_ruby(subject)).to equal(true) }
      end

      context 'for false' do
        subject { Conversion.from_ruby(false) }
        it { is_expected.to be_a(LibPython::API::PyBool_Type) }
        specify { expect(Conversion.to_ruby(subject)).to equal(false) }
      end

      [-1, 0, 1].each do |int_value|
        context "for #{int_value}" do
          let(:pyint_type) do
            if PyCall::PYTHON_VERSION >= '3'
              LibPython::API::PyLong_Type
            else 
              LibPython::API::PyInt_Type
            end
          end

          subject { Conversion.from_ruby(int_value) }
          it { is_expected.to be_kind_of(pyint_type) }
          specify { expect(Conversion.to_ruby(subject)).to eq(int_value) }
        end
      end

      [-Float::INFINITY, -1.0, 0.0, 1.0, Float::INFINITY, Float::NAN].each do |float_value|
        context "for #{float_value}" do
          subject { Conversion.from_ruby(float_value) }
          it { is_expected.to be_kind_of(LibPython::API::PyFloat_Type) }
          if float_value.nan?
            specify { expect(Conversion.to_ruby(subject)).to be_nan }
          else
            specify { expect(Conversion.to_ruby(subject)).to eq(float_value) }
          end
        end
      end

      context 'for an Array' do
        let(:ary) { [0, 1, 2, 'a', 'b', :c] }
        subject { Conversion.from_ruby(ary) }
        it { is_expected.to be_a(LibPython::API::PyList_Type) }
        specify { expect(Conversion.to_ruby(subject)).to be_a(PyCall::List) }
        specify { expect(Conversion.to_ruby(subject).to_a).to eq([0, 1, 2, 'a', 'b', 'c']) }
      end

      context 'for an Hash' do
        let(:hash) { { a: 1, b: 2, c: 3 } }
        subject { Conversion.from_ruby(hash) }
        it { is_expected.to be_a(LibPython::API::PyDict_Type) }
        specify { expect(Conversion.to_ruby(subject)).to be_a(PyCall::Dict) }
        specify { expect(Conversion.to_ruby(subject).to_h).to eq({'a' => 1, 'b' => 2, 'c' => 3}) }
      end

      context 'for :ascii_symbol' do
        subject { Conversion.from_ruby(:ascii_symbol) }
        if PyCall::LibPython::Helpers.unicode_literals?
          it { is_expected.to be_a(LibPython::API::PyUnicode_Type) }
        else
          it { is_expected.to be_a(LibPython::API::PyString_Type) }
        end
      end

      context 'for :マルチバイトシンボル' do
        subject { Conversion.from_ruby(:マルチバイトシンボル) }
        it { is_expected.to be_kind_of(LibPython::API::PyUnicode_Type) }
      end

      context 'for an ascii string' do
        subject { Conversion.from_ruby('ascii string') }
        if PyCall::LibPython::Helpers.unicode_literals?
          it { is_expected.to be_a(LibPython::API::PyUnicode_Type) }
        else
          it { is_expected.to be_a(LibPython::API::PyString_Type) }
        end
      end

      context 'for a unicode string' do
        subject { Conversion.from_ruby('ユニコード') }
        it { is_expected.to be_a(LibPython::API::PyUnicode_Type) }
      end

      context 'for a binary string' do
        subject { Conversion.from_ruby('binary string'.force_encoding(Encoding::BINARY)) }
        it { is_expected.to be_a(LibPython::API::PyString_Type) }
      end

      context 'for a Proc object' do
        let(:proc_object) { ->() {} }
        subject { Conversion.from_ruby(proc_object) }
        it { is_expected.to be_kind_of(PyRubyPtr) }
      end
    end
  end
end
