#include "pyptr.h"

#if SIZEOF_LONG >= SIZEOF_VOIDP
# define PTR2NUM(ptr) ULONG2NUM((unsigned long)(ptr))
# define NUM2PTR(num) ((void *)NUM2ULONG(num))
#else
# define PTR2NUM(ptr) ULL2NUM((unsigned LONG_LONG)(ptr))
# define NUM2PTR(num) ((void *)NUM2ULL(num))
#endif

static VALUE mPyCall;
static VALUE cPyPtr;

static PyObject *Py_None = NULL;

static void (* Py_IncRef)(PyObject *) = NULL;
static void (* Py_DecRef)(PyObject *) = NULL;
static size_t (* _PySys_GetSizeOf)(PyObject *) = NULL;

static int initialized = 0;

static VALUE
pycall_pyptr_s_get_initialized(VALUE klass)
{
  return initialized ? Qtrue : Qfalse;
}

#define INIT_PYTHON_API(type, fname) do { \
  VALUE val = rb_hash_lookup(args, ID2SYM(rb_intern(#fname))); \
  VALUE addr = rb_check_to_integer(val, "to_int"); \
  if (NIL_P(addr)) { \
    rb_raise(rb_eTypeError, "Unexpected value is given for " #fname); \
  } \
  fname = ((type)NUM2PTR(val)); \
} while (0)

static VALUE
pycall_pyptr_s_initialize(VALUE klass, VALUE args)
{
  if (initialized) return Qnil;

  Check_Type(args, T_HASH);

  INIT_PYTHON_API(PyObject *, Py_None);
  INIT_PYTHON_API(void (*)(PyObject *), Py_IncRef);
  INIT_PYTHON_API(void (*)(PyObject *), Py_DecRef);
  INIT_PYTHON_API(size_t (*)(PyObject *), _PySys_GetSizeOf);

  {
    VALUE pyptr_none = pycall_pyptr_new(Py_None);
    Py_IncRef(Py_None);
    rb_define_const(cPyPtr, "None", pyptr_none);
  }

  initialized = 1;
  return Qnil;
}

#undef INIT_PYTHON_API

static void
pycall_pyptr_free(void *ptr)
{
  /* TODO: Call Py_DecRef */
}

static size_t
pycall_pyptr_memsize(void const *ptr)
{
  if (_PySys_GetSizeOf && ptr)
    return _PySys_GetSizeOf((PyObject *)ptr);

  return 0;
}

static const rb_data_type_t pycall_pyptr_data_type = {
  "PyCall::PyPtr",
  { 0, pycall_pyptr_free, pycall_pyptr_memsize, },
#ifdef RUBY_TYPED_FREE_IMMEDIATELY
  0, 0, RUBY_TYPED_FREE_IMMEDIATELY
#endif
};

static inline PyObject*
get_pyobj_ptr(VALUE obj)
{
  PyObject *pyobj;
  TypedData_Get_Struct(obj, PyObject, &pycall_pyptr_data_type, pyobj);
  return pyobj;
}

static inline PyObject*
try_get_pyobj_ptr(VALUE obj)
{
  if (!rb_typeddata_is_kind_of(obj, &pycall_pyptr_data_type)) return NULL;
  return (PyObject*)DATA_PTR(obj);
}

PyObject*
pycall_pyptr_get_pyobj_ptr(VALUE obj)
{
  return try_get_pyobj_ptr(obj);
}

static void
raise_not_initialized(void)
{
  rb_raise(rb_eRuntimeError, "PyCall::PyPtr initialization is incomplete");
}

VALUE
pycall_pyptr_incref(VALUE pyptr)
{
  PyObject *pyobj;

  if (Py_IncRef == NULL) raise_not_initialized();

  pyobj = try_get_pyobj_ptr(pyptr);
  if (pyobj)
    (* Py_IncRef)(pyobj);
  return pyptr;
}

static VALUE
pycall_pyptr_s_incref(VALUE klass, VALUE pyptr)
{
  return pycall_pyptr_incref(pyptr);
}

VALUE
pycall_pyptr_decref(VALUE pyptr)
{
  PyObject *pyobj;

  if (Py_DecRef == NULL) raise_not_initialized();

  pyobj = try_get_pyobj_ptr(pyptr);
  if (pyobj)
    (* Py_DecRef)(pyobj);
  return pyptr;
}

static VALUE
pycall_pyptr_s_decref(VALUE klass, VALUE pyptr)
{
  return pycall_pyptr_decref(pyptr);
}

static VALUE
pycall_pyptr_s_sizeof(VALUE klass, VALUE pyptr)
{
  size_t size;
  PyObject *pyobj;
  if (_PySys_GetSizeOf == NULL) raise_not_initialized();

  pyobj = try_get_pyobj_ptr(pyptr);
  if (pyobj == NULL) return Qnil;

  size = (* _PySys_GetSizeOf)(pyobj);
  return SIZET2NUM(size);
}

static VALUE
pycall_pyptr_allocate(VALUE klass)
{
  return TypedData_Wrap_Struct(klass, &pycall_pyptr_data_type, NULL);
}

static inline VALUE
pycall_pyptr_new_with_klass(VALUE klass, PyObject *pyobj)
{
  VALUE obj = pycall_pyptr_allocate(klass);
  DATA_PTR(obj) = pyobj;
  return obj;
}

VALUE
pycall_pyptr_new(PyObject *pyobj)
{
  return pycall_pyptr_new_with_klass(cPyPtr, pyobj);
}

static VALUE
pycall_pyptr_s_new(VALUE klass, VALUE val)
{
  VALUE addr;
  PyObject *pyobj;

  addr = rb_check_to_integer(val, "to_int");
  if (NIL_P(addr)) {
    rb_raise(rb_eTypeError, "Invalid PyObject address: %"PRIsVALUE, val);
  }

  pyobj = (PyObject *)NUM2PTR(addr);
  return pycall_pyptr_new_with_klass(klass, pyobj);
}

static VALUE
pycall_pyptr_is_null(VALUE obj)
{
  PyObject* pyobj = get_pyobj_ptr(obj);
  return pyobj ? Qfalse : Qtrue;
}

static VALUE
pycall_pyptr_is_none(VALUE obj)
{
  PyObject* pyobj = get_pyobj_ptr(obj);
  return pyobj == Py_None ? Qtrue : Qfalse;
}

static VALUE
pycall_pyptr_get_address(VALUE obj)
{
  PyObject* pyobj = get_pyobj_ptr(obj);
  return PTR2NUM(pyobj);
}

static VALUE
pycall_pyptr_get_refcnt(VALUE obj)
{
  PyObject* pyobj = get_pyobj_ptr(obj);
  if (pyobj)
    return SSIZET2NUM(pyobj->ob_refcnt);
  return Qnil;
}

static VALUE
pycall_pyptr_inspect(VALUE obj)
{
  VALUE cname, str;
  PyObject* pyobj = get_pyobj_ptr(obj);

  cname = rb_class_name(CLASS_OF(obj));
  str = rb_sprintf("#<%"PRIsVALUE":%p addr=%p>", cname, (void*)obj, pyobj);
  OBJ_INFECT(str, obj);

  return str;
}

void
Init_pyptr(void)
{
  mPyCall = rb_define_module("PyCall");
  cPyPtr = rb_define_class_under(mPyCall, "PyPtr", rb_cData);

  rb_define_singleton_method(cPyPtr, "__initialize__", pycall_pyptr_s_initialize, 1);
  rb_define_singleton_method(cPyPtr, "__initialized__", pycall_pyptr_s_get_initialized, 0);

  rb_define_singleton_method(cPyPtr, "incref", pycall_pyptr_s_incref, 1);
  rb_define_singleton_method(cPyPtr, "decref", pycall_pyptr_s_decref, 1);
  rb_define_singleton_method(cPyPtr, "sizeof", pycall_pyptr_s_sizeof, 1);

  rb_define_singleton_method(cPyPtr, "new", pycall_pyptr_s_new, 1);
  rb_define_method(cPyPtr, "null?", pycall_pyptr_is_null, 0);
  rb_define_method(cPyPtr, "none?", pycall_pyptr_is_none, 0);
  rb_define_method(cPyPtr, "__address__", pycall_pyptr_get_address, 0);
  rb_define_method(cPyPtr, "__refcnt__", pycall_pyptr_get_refcnt, 0);
  rb_define_method(cPyPtr, "inspect", pycall_pyptr_inspect, 0);

  {
    VALUE pyptr_null = pycall_pyptr_new(NULL);
    rb_define_const(cPyPtr, "NULL", pyptr_null);
  }
}
