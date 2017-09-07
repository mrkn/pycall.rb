#include "pycall_internal.h"

struct enumerator_head {
    VALUE obj;
    ID    meth;
    VALUE args;
};

int
pycall_obj_is_step_range(VALUE obj)
{
  struct enumerator_head *eh;

  if (!RB_TYPE_P(obj, T_DATA)) {
    return 0;
  }

  if (!rb_obj_is_kind_of(obj, rb_cEnumerator)) {
    return 0;
  }

  eh = (struct enumerator_head *)DATA_PTR(obj);

  if (!rb_obj_is_kind_of(eh->obj, rb_cRange)) {
    return 0;
  }
  if (eh->meth == rb_intern("step")) {
    if (!RB_TYPE_P(eh->args, T_ARRAY)) {
      return 0;
    }
    return (RARRAY_LEN(eh->args) == 1);
  }

  return 0;
}

int
pycall_extract_range(VALUE obj, VALUE *pbegin, VALUE *pend, int *pexclude_end, VALUE *pstep)
{
  ID id_begin, id_end, id_exclude_end;
  VALUE begin, end, exclude_end, step = Qnil;

  CONST_ID(id_begin,       "begin");
  CONST_ID(id_end,         "end");
  CONST_ID(id_exclude_end, "exclude_end?");

  if (rb_obj_is_kind_of(obj, rb_cRange)) {
    begin = rb_funcallv(obj, id_begin, 0, 0);
    end   = rb_funcallv(obj, id_end,   0, 0);
    exclude_end = rb_funcallv(obj, id_exclude_end, 0, 0);
  }
  else if (pycall_obj_is_step_range(obj)) {
    struct enumerator_head *eh = (struct enumerator_head *)DATA_PTR(obj);
    begin = rb_funcallv(eh->obj, id_begin, 0, 0);
    end   = rb_funcallv(eh->obj, id_end,   0, 0);
    exclude_end = rb_funcallv(eh->obj, id_exclude_end, 0, 0);
    step  = RARRAY_AREF(eh->args, 0);
  }
  else {
    return 0;
  }

  if (pbegin)       *pbegin = begin;
  if (pend)         *pend = end;
  if (pexclude_end) *pexclude_end = RTEST(exclude_end);
  if (pstep)        *pstep = step;

  return 1;
}
