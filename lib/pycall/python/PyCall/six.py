import sys

PY3 = sys.version_info[0] == 3

if PY3:
  import builtins
else:
  import __builtin__ as builtins

if PY3:
  exec_ = getattr(builtins, 'exec')
else:
  def exec_(_code_, _globals_=None, _locals_=None):
    """Execute code in a namespace."""
    if _globals_ is None:
      frame = sys._getframe(1)
      _globals_ = frame.f_globals
      if _locals_ is None:
        _locals_ = frame.f_locals
      del frame
    elif _locals_ is None:
      _locals_ = _globals_
    exec("""exec _code_ in _globals_, _locals_""")
