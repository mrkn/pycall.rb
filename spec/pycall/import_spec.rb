require 'spec_helper'
require 'pycall/import'

module PyCall
  describe Import do
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
              mod.pyimport 'concurrent.futures'
            }.to raise_error(ArgumentError, /concurrent\.futures is not a valid module variable name/)
          end
        end

        context 'the as: argument is given' do
          it 'defines a method with the specified name by as: argument' do
            expect(mod).not_to be_respond_to(:futures)
            mod.pyimport 'concurrent.futures', as: 'futures'
            expect(mod.futures).to be_kind_of(PyObject)
          end
        end
      end
    end

    describe '#pyfrom' do
      context 'the import: argument is a Hash' do
        it 'defines methods with the given names in the Hash values' do
          expect(mod).not_to be_respond_to(:foo)
          expect(mod).not_to be_respond_to(:bar)
          mod.pyfrom 'multiprocessing.pool', import: { Pool: :foo, AsyncResult: :bar }
          expect(mod.foo).to be_kind_of(PyObject)
          expect(mod.bar).to be_kind_of(PyObject)
        end
      end

      context 'the import: argument is an Array' do
        it 'defines methods with the given names in the Array' do
          expect(mod).not_to be_respond_to(:Pool)
          expect(mod).not_to be_respond_to(:AsyncResult)
          mod.pyfrom 'multiprocessing.pool', import: %i[Pool AsyncResult]
          expect(mod.Pool).to be_kind_of(PyObject)
          expect(mod.AsyncResult).to be_kind_of(PyObject)
        end
      end

      context 'the import: argument is a String' do
        it 'defines a methodswith the given name' do
          expect(mod).not_to be_respond_to(:Pool)
          mod.pyfrom 'multiprocessing.pool', import: 'Pool'
          expect(mod.Pool).to be_kind_of(PyObject)
        end
      end
    end
  end
end
