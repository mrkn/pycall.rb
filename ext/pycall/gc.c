#include "pycall_internal.h"

static ID id_gcguard_table;
static PyObject *weakref_callback_pyobj;
static PyObject *gcguard_weakref_destroyed(PyObject *self, PyObject *weakref);

PyMethodDef gcguard_weakref_callback_def = {
  "_gcguard_weakref_destroyed", (PyCFunction) gcguard_weakref_destroyed, Py_METH_O
};

static PyObject *
gcguard_weakref_destroyed(PyObject *self, PyObject *weakref)
{
  pycall_gcguard_delete(weakref);
  Py_API(Py_DecRef)(weakref);

  Py_API(Py_IncRef)(Py_API(_Py_NoneStruct));
  return Py_API(_Py_NoneStruct);
}

void
pycall_gcguard_aset(PyObject *pyobj, VALUE rbobj)
{
  VALUE table = rb_ivar_get(mPyCall, id_gcguard_table);
  rb_hash_aset(table, PTR2NUM(pyobj), rbobj);
}

void
pycall_gcguard_delete(PyObject *pyobj)
{
  VALUE table = rb_ivar_get(mPyCall, id_gcguard_table);
  rb_hash_delete(table, PTR2NUM(pyobj));
}

void
pycall_gcguard_register_pyrubyobj(PyObject *pyobj)
{
  VALUE rbobj;

  if (!PyRuby_Check(pyobj)) {
    rb_raise(rb_eTypeError, "wrong type of python object %s (expect PyCall.ruby_object)", Py_TYPE(pyobj)->tp_name);
  }

  rbobj = PyRuby_get_ruby_object(pyobj);
  pycall_gcguard_aset(pyobj, rbobj);
}

void
pycall_gcguard_unregister_pyrubyobj(PyObject *pyobj)
{
  if (!PyRuby_Check(pyobj)) {
    rb_raise(rb_eTypeError, "wrong type of python object %s (expect PyCall.ruby_object)", Py_TYPE(pyobj)->tp_name);
  }

  pycall_gcguard_delete(pyobj);
}

void
pycall_gcguard_register(PyObject *pyobj, VALUE obj)
{
  PyObject *wref;

  wref = Py_API(PyWeakref_NewRef)(pyobj, weakref_callback_pyobj);
  pycall_gcguard_aset(wref, obj);
}

void
pycall_init_gcguard(void)
{
  id_gcguard_table = rb_intern("gcguard_table");
  rb_ivar_set(mPyCall, id_gcguard_table, rb_hash_new());

  weakref_callback_pyobj = Py_API(PyCFunction_NewEx)(&gcguard_weakref_callback_def, NULL, NULL);
}
