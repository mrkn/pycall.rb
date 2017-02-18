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
  end
end
