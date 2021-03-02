#include <ruby/ruby.h>

static const rb_data_type_t gvl_checker_data_type = {
  "pycall/gvl_checker",
  {
    NULL,
    NULL,
    NULL,
  },
  0, 0, RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE
gvl_checker_allocate(VALUE klass)
{
  VALUE obj = TypedData_Wrap_Struct(klass, &gvl_checker_data_type, NULL);
  return obj;
}

static VALUE
gvl_checker_has_gvl_p(VALUE obj)
{
  int ruby_thread_has_gvl_p(void);
  return ruby_thread_has_gvl_p() ? Qtrue : Qfalse;
}

void
Init_spec_helper(void)
{
  VALUE mPyCall;
  VALUE cGvlChecker;

  mPyCall = rb_define_module("PyCall");
  cGvlChecker = rb_define_class_under(mPyCall, "GvlChecker", rb_cObject);
  rb_define_alloc_func(cGvlChecker, gvl_checker_allocate);
  rb_define_method(cGvlChecker, "has_gvl?", gvl_checker_has_gvl_p, 0);
  rb_define_method(cGvlChecker, "call", gvl_checker_has_gvl_p, 0);
}
