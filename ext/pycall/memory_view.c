#ifdef HAVE_RUBY_MEMORY_VIEW_H
# include <ruby/memory_view.h>

static bool pycall_get_memory_view(VALUE obj, rb_memory_view_t *view, int flags);
static bool pycall_release_memory_view(VALUE obj, rb_memory_view_t *view);
static bool pycall_memory_view_available_p(VALUE obj);

static rb_memory_view_entry_t pycall_memory_view_entry = {
  pycall_get_memory_view,
  pycall_release_memory_view,
  pycall_memory_view_available_p,
};


static bool
pycall_get_memory_view(VALUE obj, rb_memory_view_t *view, int flags)
{
}

static bool
pycall_release_memory_view(VALUE obj, rb_memory_view_t *view)
{
}

static bool
pycall_memory_view_available_p(VALUE obj)
{
}

void
pycall_init_memory_view(void)
{
  rb_memory_view_register();
}
#else
void
pycall_init_memory_view(void)
{
}
#endif
