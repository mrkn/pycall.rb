require 'spec_helper'

module PyCall::LibPython
  RSpec.describe PyTypeObjectStruct do
    describe '.new' do
      specify 'for a simple class' do
        expect { |b|
          begin
            dealloc_func = FFI::Function.new(:void, [PyObjectStruct.ptr], &b)
            pytype = PyTypeObjectStruct.new(
              'PyCall.test_class',
              PyObjectStruct.size + FFI.type_size(:pointer)
            ) do |t|
              t[:tp_dealloc] = dealloc_func
            end
            pyobj = PyCall::LibPython._PyObject_New(pytype)
            expect(pyobj[:ob_type].pointer).to eq(pytype.pointer)
            PyCall::LibPython.Py_DecRef(pyobj)
          ensure
            PyCall::LibPython.Py_DecRef(pytype) if pytype
          end
        }.to yield_with_args(an_instance_of(PyObjectStruct))
      end

      specify 'for a subclass' do
        expect { |b|
          begin
            dealloc_func = FFI::Function.new(:void, [PyObjectStruct.ptr], &b)
            pytype = PyTypeObjectStruct.new(
              'PyCall.test_base_class',
              PyObjectStruct.size + FFI.type_size(:pointer)
            ) do |t|
              t[:tp_flags] |= Py_TPFLAGS_BASETYPE
              t[:tp_dealloc] = dealloc_func
            end
            pysubtype = PyTypeObjectStruct.new(
              'PyCall.test_base_class',
              PyObjectStruct.size + 2*FFI.type_size(:pointer),
            ) do |t|
              t[:tp_base] = pytype
              PyCall::LibPython.Py_IncRef(pytype)
            end
            expect(pysubtype[:tp_dealloc]).to eq(pytype[:tp_dealloc])
            pyobj = PyCall::LibPython._PyObject_New(pysubtype)
            expect(pyobj[:ob_type].pointer).to eq(pysubtype.pointer)
            PyCall::LibPython.Py_DecRef(pyobj)
          ensure
            PyCall::LibPython.Py_DecRef(pysubtype) if pysubtype
            PyCall::LibPython.Py_DecRef(pytype) if pytype
          end
        }.to yield_with_args(an_instance_of(PyObjectStruct))
      end
    end
  end
end
