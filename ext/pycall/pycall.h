#ifndef PYCALL_H
#define PYCALL_H 1

#if defined(__cplusplus)
extern "C" {
#if 0
} /* satisfy cc-mode */
#endif
#endif

VALUE pycall_pyptr_new(PyObject *pyobj);
PyObject *pycall_pyptr_get_pyobj_ptr(VALUE pyptr);

#if defined(__cplusplus)
#if 0
{ /* satisfy cc-mode */
#endif
} /* extern "C" { */
#endif

#endif /* PYCALL_H */
