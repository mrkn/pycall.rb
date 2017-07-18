#ifndef PYCALL_PYPTR_H
#define PYCALL_PYPTR_H 1

#if defined(__cplusplus)
extern "C" {
#if 0
} /* satisfy cc-mode */
#endif
#endif

#include <ruby/ruby.h>
#include <inttypes.h>

typedef intptr_t Py_intptr_t;

#ifdef HAVE_SSIZE_T
typedef ssize_t Py_ssize_t;
#elif SIZEOF_VOID_P == SIZEOF_SIZE_T
typedef Py_intptr_t Py_ssize_t;
#else
# error "Unable to typedef Py_ssize_t."
#endif

#define SIZEOF_PY_HASH_T SIZEOF_SIZE_T
typedef Py_ssize_t Py_hash_t;

#define PyObject_VAR_HEAD      PyVarObject ob_base;

/* NOTE: Currently Py_TRACE_REFS is not supported */
typedef struct _object {
  Py_ssize_t ob_refcnt;
  struct _typeobject *ob_type;
} PyObject;

typedef struct {
  PyObject ob_base;
  Py_ssize_t ob_size; /* Number of items in variable part */
} PyVarObject;

#define Py_REFCNT(ob)           (((PyObject*)(ob))->ob_refcnt)
#define Py_TYPE(ob)             (((PyObject*)(ob))->ob_type)
#define Py_SIZE(ob)             (((PyVarObject*)(ob))->ob_size)

typedef PyObject * (*unaryfunc)(PyObject *);
typedef PyObject * (*binaryfunc)(PyObject *, PyObject *);
typedef PyObject * (*ternaryfunc)(PyObject *, PyObject *, PyObject *);
typedef int (*inquiry)(PyObject *);
typedef Py_ssize_t (*lenfunc)(PyObject *);
typedef PyObject *(*ssizeargfunc)(PyObject *, Py_ssize_t);
typedef int(*ssizeobjargproc)(PyObject *, Py_ssize_t, PyObject *);
typedef int(*objobjargproc)(PyObject *, PyObject *, PyObject *);

typedef struct bufferinfo {
  void *buf;
  PyObject *obj;        /* owned reference */
  Py_ssize_t len;
  Py_ssize_t itemsize;  /* This is Py_ssize_t so it can be
			   pointed to by strides in simple case.*/
  int readonly;
  int ndim;
  char *format;
  Py_ssize_t *shape;
  Py_ssize_t *strides;
  Py_ssize_t *suboffsets;
  void *internal;
} Py_buffer;

typedef int (*getbufferproc)(PyObject *, Py_buffer *, int);
typedef void (*releasebufferproc)(PyObject *, Py_buffer *);

typedef int (*objobjproc)(PyObject *, PyObject *);
typedef int (*visitproc)(PyObject *, void *);
typedef int (*traverseproc)(PyObject *, visitproc, void *);

typedef struct {
    /* Number implementations must check *both*
       arguments for proper type and implement the necessary conversions
       in the slot functions themselves. */

    binaryfunc nb_add;
    binaryfunc nb_subtract;
    binaryfunc nb_multiply;
    binaryfunc nb_remainder;
    binaryfunc nb_divmod;
    ternaryfunc nb_power;
    unaryfunc nb_negative;
    unaryfunc nb_positive;
    unaryfunc nb_absolute;
    inquiry nb_bool;
    unaryfunc nb_invert;
    binaryfunc nb_lshift;
    binaryfunc nb_rshift;
    binaryfunc nb_and;
    binaryfunc nb_xor;
    binaryfunc nb_or;
    unaryfunc nb_int;
    void *nb_reserved;  /* the slot formerly known as nb_long */
    unaryfunc nb_float;

    binaryfunc nb_inplace_add;
    binaryfunc nb_inplace_subtract;
    binaryfunc nb_inplace_multiply;
    binaryfunc nb_inplace_remainder;
    ternaryfunc nb_inplace_power;
    binaryfunc nb_inplace_lshift;
    binaryfunc nb_inplace_rshift;
    binaryfunc nb_inplace_and;
    binaryfunc nb_inplace_xor;
    binaryfunc nb_inplace_or;

    binaryfunc nb_floor_divide;
    binaryfunc nb_true_divide;
    binaryfunc nb_inplace_floor_divide;
    binaryfunc nb_inplace_true_divide;

    unaryfunc nb_index;

    binaryfunc nb_matrix_multiply;
    binaryfunc nb_inplace_matrix_multiply;
} PyNumberMethods;

typedef struct {
    lenfunc sq_length;
    binaryfunc sq_concat;
    ssizeargfunc sq_repeat;
    ssizeargfunc sq_item;
    void *was_sq_slice;
    ssizeobjargproc sq_ass_item;
    void *was_sq_ass_slice;
    objobjproc sq_contains;

    binaryfunc sq_inplace_concat;
    ssizeargfunc sq_inplace_repeat;
} PySequenceMethods;

typedef struct {
  lenfunc mp_length;
  binaryfunc mp_subscript;
  objobjargproc mp_ass_subscript;
} PyMappingMethods;

typedef struct {
  unaryfunc am_await;
  unaryfunc am_aiter;
  unaryfunc am_anext;
} PyAsyncMethods;

typedef struct {
     getbufferproc bf_getbuffer;
     releasebufferproc bf_releasebuffer;
} PyBufferProcs;

typedef void (*freefunc)(void *);
typedef void (*destructor)(PyObject *);
typedef int (*printfunc)(PyObject *, FILE *, int);
typedef PyObject *(*getattrfunc)(PyObject *, char *);
typedef PyObject *(*getattrofunc)(PyObject *, PyObject *);
typedef int (*setattrfunc)(PyObject *, char *, PyObject *);
typedef int (*setattrofunc)(PyObject *, PyObject *, PyObject *);
typedef PyObject *(*reprfunc)(PyObject *);
typedef Py_hash_t (*hashfunc)(PyObject *);
typedef PyObject *(*richcmpfunc) (PyObject *, PyObject *, int);
typedef PyObject *(*getiterfunc) (PyObject *);
typedef PyObject *(*iternextfunc) (PyObject *);
typedef PyObject *(*descrgetfunc) (PyObject *, PyObject *, PyObject *);
typedef int (*descrsetfunc) (PyObject *, PyObject *, PyObject *);
typedef int (*initproc)(PyObject *, PyObject *, PyObject *);
typedef PyObject *(*newfunc)(struct _typeobject *, PyObject *, PyObject *);
typedef PyObject *(*allocfunc)(struct _typeobject *, Py_ssize_t);

typedef struct _typeobject {
  PyObject_VAR_HEAD
    const char *tp_name; /* For printing, in format "<module>.<name>" */
  Py_ssize_t tp_basicsize, tp_itemsize; /* For allocation */

  /* Methods to implement standard operations */

  destructor tp_dealloc;
  printfunc tp_print;
  getattrfunc tp_getattr;
  setattrfunc tp_setattr;
  PyAsyncMethods *tp_as_async; /* formerly known as tp_compare (Python 2)
                                  or tp_reserved (Python 3) */
  reprfunc tp_repr;

  /* Method suites for standard classes */

  PyNumberMethods *tp_as_number;
  PySequenceMethods *tp_as_sequence;
  PyMappingMethods *tp_as_mapping;

  /* More standard operations (here for binary compatibility) */

  hashfunc tp_hash;
  ternaryfunc tp_call;
  reprfunc tp_str;
  getattrofunc tp_getattro;
  setattrofunc tp_setattro;

  /* Functions to access object as input/output buffer */
  PyBufferProcs *tp_as_buffer;

  /* Flags to define presence of optional/expanded features */
  unsigned long tp_flags;

  const char *tp_doc; /* Documentation string */

  /* Assigned meaning in release 2.0 */
  /* call function for all accessible objects */
  traverseproc tp_traverse;

  /* delete references to contained objects */
  inquiry tp_clear;

  /* Assigned meaning in release 2.1 */
  /* rich comparisons */
  richcmpfunc tp_richcompare;

  /* weak reference enabler */
  Py_ssize_t tp_weaklistoffset;

  /* Iterators */
  getiterfunc tp_iter;
  iternextfunc tp_iternext;

  /* Attribute descriptor and subclassing stuff */
  struct PyMethodDef *tp_methods;
  struct PyMemberDef *tp_members;
  struct PyGetSetDef *tp_getset;
  struct _typeobject *tp_base;
  PyObject *tp_dict;
  descrgetfunc tp_descr_get;
  descrsetfunc tp_descr_set;
  Py_ssize_t tp_dictoffset;
  initproc tp_init;
  allocfunc tp_alloc;
  newfunc tp_new;
  freefunc tp_free; /* Low-level free-memory routine */
  inquiry tp_is_gc; /* For PyObject_IS_GC */
  PyObject *tp_bases;
  PyObject *tp_mro; /* method resolution order */
  PyObject *tp_cache;
  PyObject *tp_subclasses;
  PyObject *tp_weaklist;
  destructor tp_del;

  /* Type attribute cache version tag. Added in version 2.6 */
  unsigned int tp_version_tag;

  destructor tp_finalize;

#ifdef COUNT_ALLOCS
  /* these must be last and never explicitly initialized */
  Py_ssize_t tp_allocs;
  Py_ssize_t tp_frees;
  Py_ssize_t tp_maxalloc;
  struct _typeobject *tp_prev;
  struct _typeobject *tp_next;
#endif
} PyTypeObject;

#define Py_TPFLAGS_HAVE_GC (1L<<14)

/* Type is abstract and cannot be instantiated */
#define Py_TPFLAGS_IS_ABSTRACT (1L<<20)

/* These flags are used to determine if a type is a subclass. */
#define Py_TPFLAGS_INT_SUBCLASS         (1L<<23)
#define Py_TPFLAGS_LONG_SUBCLASS        (1L<<24)
#define Py_TPFLAGS_LIST_SUBCLASS        (1L<<25)
#define Py_TPFLAGS_TUPLE_SUBCLASS       (1L<<26)
#define Py_TPFLAGS_BYTES_SUBCLASS       (1L<<27)
#define Py_TPFLAGS_UNICODE_SUBCLASS     (1L<<28)
#define Py_TPFLAGS_DICT_SUBCLASS        (1L<<29)
#define Py_TPFLAGS_BASE_EXC_SUBCLASS    (1L<<30)
#define Py_TPFLAGS_TYPE_SUBCLASS        (1L<<31)

#define Py_TPFLAGS_DEFAULT  ( \
                 Py_TPFLAGS_HAVE_STACKLESS_EXTENSION | \
                 Py_TPFLAGS_HAVE_VERSION_TAG | \
                0)

#define PyType_HasFeature(t, f)  (((t)->tp_flags & (f)) != 0)

#define PyType_IS_GC(t) PyType_HasFeature((t), Py_TPFLAGS_HAVE_GC)
#define PyObject_IS_GC(o) (PyType_IS_GC(Py_TYPE(o)) && \
    (Py_TYPE(o)->tp_is_gc == NULL || Py_TYPE(o)->tp_is_gc(o)))

typedef union _gc_head {
  struct {
    union _gc_head *gc_next;
    union _gc_head *gc_prev;
    Py_ssize_t gc_refs;
  } gc;
  long double dummy;  /* force worst-case alignment */
} PyGC_Head;

PyObject* pycall_pyptr_get_pyobj_ptr(VALUE obj);
VALUE pycall_pyptr_new(PyObject *pyobj);
VALUE pycall_pyptr_incref(VALUE pyptr);
VALUE pycall_pyptr_decref(VALUE pyptr);
VALUE pycall_pytypeptr_new(PyTypeObject *pytypeobj);

#if defined(__cplusplus)
#if 0
{ /* satisfy cc-mode */
#endif
} /* extern "C" { */
#endif

#endif /* PYCALL_PYPTR_H */
