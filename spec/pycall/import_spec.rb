require 'spec_helper'
require 'pycall/import'

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
            expect(mod.time).to be_kind_of(PyObject)
          end
        end

        context 'the as: argument is given' do
          it 'defines a method with the specified name by as: argument' do
            expect(mod).not_to be_respond_to(:tm)
            mod.pyimport 'time', as: 'tm'
            expect(mod.tm).to be_kind_of(PyObject)
          end
        end
      end

      context 'the given module name includes "."' do
        context 'the as: argument is not given' do
          it 'raises ArgumentError' do
            expect {
              mod.pyimport 'multiprocessing.pool'
            }.to raise_error(ArgumentError, /multiprocessing\.pool is not a valid module variable name/)
          end
        end

        context 'the as: argument is given' do
          it 'defines a method with the specified name by as: argument' do
            expect(mod).not_to be_respond_to(:pool)
            mod.pyimport 'multiprocessing.pool', as: 'pool'
            expect(mod.pool).to be_kind_of(PyObject)
          end
        end
      end
    end

    describe '#pyfrom' do
      context 'the import: argument is a Hash' do
        it 'defines methods with the given names in the Hash values' do
          expect(mod).not_to be_respond_to(:foo)
          expect(mod).not_to be_respond_to(:bar)
          mod.pyfrom 'multiprocessing', import: { Process: :foo, Queue: :bar }
          expect(mod.foo).to be_kind_of(PyCall::TypeObject)
          expect(mod.bar).to be_kind_of(PyObject)
        end
      end

      context 'the import: argument is an Array' do
        it 'defines methods with the given names in the Array' do
          expect(mod).not_to be_respond_to(:Process)
          expect(mod).not_to be_respond_to(:Queue)
          mod.pyfrom 'multiprocessing', import: %i[Process Queue]
          expect(mod::Process).to be_kind_of(PyCall::TypeObject)
          expect(mod::Queue).to be_kind_of(PyObject)
        end
      end

      context 'the import: argument is a String' do
        it 'defines a methodswith the given name' do
          expect(mod).not_to be_respond_to(:Queue)
          mod.pyfrom 'multiprocessing', import: 'Queue'
          expect(mod::Queue).to be_kind_of(PyObject)
        end
      end

      context 'there is not the module with the given name' do
        it 'raises an error' do
          expect {
            mod.pyfrom 'foo', import: 'bar'
          }.to raise_error(PyCall::PyError)
        end
      end
    end
  end
end
