require 'spec_helper'

module PyCall
  ::RSpec.describe PyTypeObjectWrapper do
    let(:simple_class) do
      PyCall.import_module('pycall.simple_class').SimpleClass.__pyptr__
    end

    let(:simple_class_wrapper) do
      PyCall.wrap_class(simple_class)
    end

    describe '#subclass?(other)' do
      subject { PyCall.builtins.list }

      context 'when the value of other is a PyTypeObjectWrapper' do
        specify do
          expect(subject.subclass?(PyCall.builtins.object)).to eq(true)
          expect(subject.subclass?(PyCall.builtins.list)).to eq(true)
          expect(subject.subclass?(PyCall.builtins.dict)).to eq(false)
        end
      end

      context 'when the value of other is a Class' do
        specify do
          expect(subject.subclass?(Object)).to eq(true)
          expect(subject.subclass?(PyObjectWrapper)).to eq(true)
          expect(subject.subclass?(PyTypeObjectWrapper)).to eq(false)
          expect(subject.subclass?(Array)).to eq(false)
        end
      end

      context 'when the other cases' do
        it 'behaves as well as PyTypePtr#subclass?' do
          expect(subject.subclass?(PyCall.builtins.object.__pyptr__)).to eq(true)
          expect(subject.subclass?(PyCall.builtins.list.__pyptr__)).to eq(true)
          expect(subject.subclass?(PyCall.builtins.dict.__pyptr__)).to eq(false)
          expect { subject.subclass?(Conversion.from_ruby(12)) }.to raise_error(TypeError)
          expect { subject.subclass?(12) }.to raise_error(TypeError)
        end
      end
    end

    describe '#<=>(other)' do
      context 'when the value of other is a PyTypeObjectWrapper' do
        context 'when the given class is a superclass in Python of the receiver' do
          it 'returns -1' do
            expect(PyCall.builtins.list <=> PyCall.builtins.object).to eq(-1)
          end
        end

        context 'when the given class is a subclass in Python of the receiver' do
          it 'returns 1' do
            expect(PyCall.builtins.object <=> PyCall.builtins.list).to eq(1)
          end
        end

        context 'when the given class is the receiver' do
          it 'returns 0' do
            expect(PyCall.builtins.list <=> PyCall.builtins.list).to eq(0)
          end
        end
      end

      context 'when the value of other is a PyTypePtr' do
        context 'when the given class is a superclass in Python of the receiver' do
          it 'returns -1' do
            expect(PyCall.builtins.list <=> PyCall.builtins.object.__pyptr__).to eq(-1)
          end
        end

        context 'when the given class is a subclass in Python of the receiver' do
          it 'returns 1' do
            expect(PyCall.builtins.object <=> PyCall.builtins.list.__pyptr__).to eq(1)
          end
        end

        context 'when the given class is the receiver' do
          it 'returns 0' do
            expect(PyCall.builtins.list <=> PyCall.builtins.list.__pyptr__).to eq(0)
          end
        end
      end

      context 'when the value of other is a Class' do
        context 'when the given class is a superclass of the receiver' do
          it 'returns -1' do
            expect(PyCall.builtins.list <=> Object).to eq(-1)
            expect(PyCall.builtins.list <=> PyObjectWrapper).to eq(-1)
          end
        end

        context 'when the given class is a subclass of the receiver' do
          let(:subclass) { Class.new(PyCall.builtins.list) }

          it 'returns 1' do
            expect(PyCall.builtins.list <=> subclass).to eq(1)
          end
        end

        context 'when the given class is neither a superclass or a subclass of the receiver' do
          it 'returns nil' do
            expect(PyCall.builtins.list <=> PyTypeObjectWrapper).to eq(nil)
            expect(PyCall.builtins.list <=> Array).to eq(nil)
          end
        end
      end

      context 'when the other cases' do
        it 'returns nil' do
          expect(PyCall.builtins.list <=> Conversion.from_ruby(42)).to eq(nil)
          expect(PyCall.builtins.list <=> 42).to eq(nil)
        end
      end
    end

    describe '#<' do
      specify do
        expect(PyCall.builtins.list < PyCall.builtins.list).to eq(false)
        expect(PyCall.builtins.list < PyCall.builtins.object).to eq(true)
        expect(PyCall.builtins.object < PyCall.builtins.list).to eq(false)
        expect(PyCall.builtins.list < PyCall.builtins.dict).to eq(nil)
        expect(PyCall.builtins.list < Object).to eq(true)
        expect(PyCall.builtins.list < Array).to eq(nil)
        expect(PyCall.builtins.list < Conversion.from_ruby(42)).to eq(nil)
        expect(PyCall.builtins.list < 42).to eq(nil)
      end
    end

    describe '#>' do
      specify do
        expect(PyCall.builtins.list > PyCall.builtins.list).to eq(false)
        expect(PyCall.builtins.list > PyCall.builtins.object).to eq(false)
        expect(PyCall.builtins.object > PyCall.builtins.list).to eq(true)
        expect(PyCall.builtins.list > PyCall.builtins.dict).to eq(nil)
        expect(PyCall.builtins.list > Object).to eq(false)
        expect(PyCall.builtins.list > Array).to eq(nil)
        expect(PyCall.builtins.list > Conversion.from_ruby(42)).to eq(nil)
        expect(PyCall.builtins.list > 42).to eq(nil)
      end
    end

    describe '#<=' do
      specify do
        expect(PyCall.builtins.list <= PyCall.builtins.list).to eq(true)
        expect(PyCall.builtins.list <= PyCall.builtins.object).to eq(true)
        expect(PyCall.builtins.object <= PyCall.builtins.list).to eq(false)
        expect(PyCall.builtins.list <= PyCall.builtins.dict).to eq(nil)
        expect(PyCall.builtins.list <= Object).to eq(true)
        expect(PyCall.builtins.list <= Array).to eq(nil)
        expect(PyCall.builtins.list <= Conversion.from_ruby(42)).to eq(nil)
        expect(PyCall.builtins.list <= 42).to eq(nil)
      end
    end

    describe '#>=' do
      specify do
        expect(PyCall.builtins.list >= PyCall.builtins.list).to eq(true)
        expect(PyCall.builtins.list >= PyCall.builtins.object).to eq(false)
        expect(PyCall.builtins.object >= PyCall.builtins.list).to eq(true)
        expect(PyCall.builtins.list >= PyCall.builtins.dict).to eq(nil)
        expect(PyCall.builtins.list >= Object).to eq(false)
        expect(PyCall.builtins.list >= Array).to eq(nil)
        expect(PyCall.builtins.list >= Conversion.from_ruby(42)).to eq(nil)
        expect(PyCall.builtins.list >= 42).to eq(nil)
      end
    end

    describe '#===' do
      specify do
        expect(PyCall.builtins.tuple === PyCall.tuple()).to eq(true)
        np = PyCall.import_module('numpy')
        expect(np.int64 === np.asarray([1])[0]).to eq(true)
        expect(np.integer === np.asarray([1])[0]).to eq(true)
      end
    end

    describe '.extend_object' do
      context '@__pyptr__ of the extended object is a PyCall::PyTypePtr' do
        it 'extends the given object' do
          cls = Class.new
          cls.instance_variable_set(:@__pyptr__, LibPython::API::PyType_Type)
          expect { cls.extend PyTypeObjectWrapper }.not_to raise_error
          expect(cls).to be_a(PyTypeObjectWrapper)
        end
      end

      context '@__pyptr__ of the extended object is a PyCall::PyPtr' do
        it 'raises TypeError' do
          cls = Class.new
          cls.instance_variable_set(:@__pyptr__, PyPtr::NULL)
          expect { cls.extend PyTypeObjectWrapper }.to raise_error(TypeError, /@__pyptr__/)
          expect(cls).not_to be_a(PyTypeObjectWrapper)
        end
      end

      context '@__pyptr__ of the extended object is nil' do
        it 'raises TypeError' do
          cls = Class.new
          expect { cls.extend PyTypeObjectWrapper }.to raise_error(TypeError, /@__pyptr__/)
          expect(cls).not_to be_a(PyTypeObjectWrapper)
        end
      end

      context '@__pyptr__ of the extended object is not a PyCall::PyPtr' do
        it 'raises TypeError' do
          cls = Class.new
          cls.instance_variable_set(:@__pyptr__, 42)
          expect { cls.extend PyTypeObjectWrapper }.to raise_error(TypeError, /@__pyptr__/)
          expect(cls).not_to be_a(PyTypeObjectWrapper)
        end
      end
    end

    describe '.register_python_type_mapping' do
      pending
    end

    describe '.new' do
      let(:extended_class) { Class.new }

      before do
        extended_class.instance_variable_set(:@__pyptr__, simple_class)
        extended_class.extend PyTypeObjectWrapper
      end

      it 'returns an instance of the extended class object' do
        obj = extended_class.new
        expect(obj).to be_a(extended_class)
        expect(obj.x).to eq(0)
      end

      it 'calls the corresponding Python type object with the given arguments to instantiate its Python object' do
        obj = extended_class.new(42)
        expect(obj.x).to eq(42)
      end

      specify 'the returned object has a Python object pointer whose type is its __pyptr__' do
        obj = extended_class.new
        expect(obj.__pyptr__.__ob_type__).to eq(simple_class_wrapper)
      end

      it 'calls __init__ only once' do
        test_class = PyCall.import_module('pycall.initialize_test').InitializeTest
        obj = test_class.new(42)
        expect(obj.values.to_a).to eq([42])
      end

      context 'when __new__ is redefined' do
        it 'calls __init__ only once' do
          test_class = PyCall.import_module('pycall.initialize_test').NewOverrideTest
          obj = test_class.new(42)
          expect(obj.values.to_a).to eq([42, 42])
        end
      end
    end
  end
end
