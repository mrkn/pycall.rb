#include <ruby/ruby.h>

static VALUE mPyCall;
static VALUE cPyPtr;

void
Init_pyptr(void)
{
  mPyCall = rb_define_module("PyCall");
  cPyPtr = rb_define_class_under(mPyCall, "PyPtr", rb_cData);
}
