require 'spec_helper'

module PyCall
  ::RSpec.describe Import do
    let(:mod) { Module.new }

    before { mod.extend PyCall::Import }

    describe '#pyimport' do
      context 'the given module name does not include "."' do
        context 'the as: argument is not given' do
          it 'defines a method with the specified module name' do
            expect(mod).not_to be_respond_to(:time)
            mod.pyimport 'time'
            expect(mod.time).to be_kind_of(PyObjectWrapper)
          end
        end

        context 'the as: argument is given' do
          it 'defines a method with the specified name by as: argument' do
            expect(mod).not_to be_respond_to(:tm)
            mod.pyimport 'time', as: 'tm'
            expect(mod.tm).to be_kind_of(PyObjectWrapper)
          end
        end
      end

      context 'the given module name includes "."' do
        context 'the as: argument is not given' do
          # TODO: This example describes an undesired behavior that should be fixed.
          it 'raises ArgumentError' do
            expect {
              mod.pyimport 'pycall.import_test'
            }.to raise_error(ArgumentError, /pycall\.import_test is not a valid module variable name/)
          end
        end

        context 'the as: argument is given' do
          it 'defines a method with the specified name by as: argument' do
            expect(mod).not_to be_respond_to(:pool)
            mod.pyimport 'pycall.import_test', as: 'import_test'
            expect(mod.import_test).to be_kind_of(PyObjectWrapper)
          end
        end
      end
    end

    describe '#pyfrom' do
      context 'the import: argument is a Hash' do
        it 'defines methods with the given names in the Hash values' do
          expect(mod).not_to be_respond_to(:foo)
          expect(mod).not_to be_respond_to(:bar)
          mod.pyfrom 'pycall.import_test', import: { Foo: :foo, TestClass: :bar, to_list: :to_list }
          expect(mod.foo).to be_kind_of(PyTypeObjectWrapper)
          expect(mod.bar).to be_kind_of(PyObjectWrapper)
          expect(mod.to_list(42)).to eq(PyCall::List.new([42]))
        end
      end

      context 'the import: argument is an Array' do
        it 'defines methods with the given names in the Array' do
          expect(mod).not_to be_respond_to(:Process)
          expect(mod).not_to be_respond_to(:Queue)
          mod.pyfrom 'pycall.import_test', import: %i[Foo TestClass]
          expect(mod::Foo).to be_kind_of(PyTypeObjectWrapper)
          expect(mod::TestClass).to be_kind_of(PyObjectWrapper)
        end
      end

      context 'the import: argument is a String' do
        it 'defines a methodswith the given name' do
          expect(mod).not_to be_respond_to(:Queue)
          mod.pyfrom 'pycall.import_test', import: 'TestClass'
          expect(mod::TestClass).to be_kind_of(PyObjectWrapper)
        end
        it 'defines a class and its initializer (singleton method) with the given name via hiearachical signature of modules' do
          expect(mod).not_to be_respond_to(:TestClass)
          mod.pyfrom 'pycall.import_test.TestClass', import: 'TestClass'
          expect(mod::TestClass.class).to eq(Class)
          expect(mod.TestClass(42).class).to eq(Object)
          expect(mod.TestClass(42).test()).to eq('42')
        end
      end

      context 'there is not the module with the given name' do
        it 'raises an error' do
          expect {
            mod.pyfrom 'foo', import: 'bar'
          }.to raise_error(PyCall::PyError)
        end
      end

      context 'there is not the attribute specified in import: argument' do
        context 'but there is a module with the same name and it has the attribute with the same name' do
          it 'imports the attribute' do
            expect(mod).not_to be_respond_to(:TestClass)
            mod.pyfrom 'pycall.import_test', import: :TestClass
            expect(mod).to be_const_defined(:TestClass)
            expect(mod::TestClass.TestClass).to be_a(PyTypeObjectWrapper)
            # XXX: expect(mod::TestClass.TestClass(42).test()).to eq('42')
          end
        end
      end
    end
  end
end
