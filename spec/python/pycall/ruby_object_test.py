def call_callable(f, x):
    return f(str(x))

def test_ruby_object_attr(ro):
    return ro.attr()

def test_ruby_object_method(ro):
    return ro.smethod(42)
