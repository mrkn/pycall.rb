#include "pycall_internal.h"

struct gcguard {
  st_table *guarded_objects;
};

static int
gcguard_mark_i(st_data_t key, st_data_t val, st_data_t arg)
{
  VALUE obj = (VALUE)val;
  rb_gc_mark(obj);
  return ST_CONTINUE;
}

static void
gcguard_mark(void* ptr)
{
  struct gcguard *gg = (struct gcguard *)ptr;
  st_foreach(gg->guarded_objects, gcguard_mark_i, 0);
}

static void
gcguard_free(void* ptr)
{
  struct gcguard *gg = (struct gcguard *)ptr;
  st_free_table(gg->guarded_objects);
}

static size_t
gcguard_memsize(const void* ptr)
{
  const struct gcguard *gg = (const struct gcguard *)ptr;
  return st_memsize(gg->guarded_objects);
}

static rb_data_type_t gcguard_data_type = {
  "PyCall::gcguard",
  {
    gcguard_mark,
    gcguard_free,
    gcguard_memsize,
  },
#ifdef RUBY_TYPED_FREE_IMMEDIATELY
  0, 0, RUBY_TYPED_FREE_IMMEDIATELY
#endif
};

static void
gcguard_aset(VALUE gcguard, PyObject *pyptr, VALUE rbobj)
{
  struct gcguard *gg;
  TypedData_Get_Struct(gcguard, struct gcguard, &gcguard_data_type, gg);

  st_insert(gg->guarded_objects, (st_data_t)pyptr, (st_data_t)rbobj);
}

static void
gcguard_delete(VALUE gcguard, PyObject *pyptr)
{
  if (rb_typeddata_is_kind_of(gcguard, &gcguard_data_type)) {
    /* This check is necessary to avoid error on the process finalization phase */
    struct gcguard *gg;
    st_data_t key, val;

    TypedData_Get_Struct(gcguard, struct gcguard, &gcguard_data_type, gg);

    key = (st_data_t)pyptr;
    st_delete(gg->guarded_objects, &key, &val);
  }
}

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
  VALUE gcguard = rb_ivar_get(mPyCall, id_gcguard_table);
  gcguard_aset(gcguard, pyobj, rbobj);
}

void
pycall_gcguard_delete(PyObject *pyobj)
{
  VALUE gcguard = rb_ivar_get(mPyCall, id_gcguard_table);
  gcguard_delete(gcguard, pyobj);
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

static VALUE
gcguard_new(void)
{
  struct gcguard *gg;
  VALUE obj = TypedData_Make_Struct(0, struct gcguard, &gcguard_data_type, gg);
  gg->guarded_objects = st_init_numtable();

  return obj;
}

void
pycall_init_gcguard(void)
{
  id_gcguard_table = rb_intern("gcguard_table");
  rb_ivar_set(mPyCall, id_gcguard_table, gcguard_new());

  weakref_callback_pyobj = Py_API(PyCFunction_NewEx)(&gcguard_weakref_callback_def, NULL, NULL);
}
