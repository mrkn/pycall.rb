=begin

PyCall bildet alle Python-built-in Methoden als Instanz- und Klassenmethoden ab

=end
module PyCall

  const_set(:PYTHON_VERSION, Polyglot.eval('python', 'import sys;sys.version.split(" ")[0]'))
  const_set(:PYTHON_DESCRIPTION, Polyglot.eval('python', 'import sys;sys.version'))

  require 'pycall/truffleruby/libpython'

  def self.init(python = ENV['PYTHON'])
    true
  end

  require 'pycall/truffleruby/pyobject_wrapper'
  require 'pycall/truffleruby/pymodule_wrapper'
  require 'pycall/truffleruby/pytypeobject_wrapper'
  require 'pycall/truffleruby/conversion'
  require 'pycall/truffleruby/pyerror'

  module_function

  def import_module(name)
    PyModuleWrapper.wrap(Polyglot.eval('python', "import #{name}\n#{name}"))
  end

  def builtins
    @@builtins ||= PyModuleWrapper.wrap(import_module('builtins'))
  end

  def callable?(obj)
    @@callable ||= Polyglot.eval('python', 'callable')
    @@callable.call(obj)
  end

  def dir(obj)
    obj.__dir__()
  end

  def eval(expr, globals: nil, locals: nil)
    PyObjectWrapper.wrap(Polyglot.eval('python', expr))
  end

  def exec(code, globals: nil, locals: nil)
    PyObjectWrapper.wrap(Polyglot.eval('python', expr))
  end

  def to_py_complex(number)#TODO: delete if Graal supports Complex Numbers in Polyglot way
    @@python_complex_helper = Polyglot.eval('python', 'lambda x,y: x+y*1j')
    @@python_complex_helper.call(number.real, number.imag)
  end

  def from_py_complex(number)#TODO: delete if Graal supports Complex Numbers in Polyglot way
    @@python_complex_split = Polyglot.eval('python', 'lambda x: (x.real, x.imag)')
    splitted = @@python_complex_split.call(number)
    splitted[0] + splitted[1] * 1i
  end

  def getattr(*args)
    obj, *rest = args
    if obj.is_a?(PyObjectWrapper)
      obj = obj.__pyptr__
    end
    @@getattr_py ||= Polyglot.eval('python', 'getattr')
    PyObjectWrapper.wrap(@@getattr_py.call(obj, *rest))
  end

  def hasattr?(obj, name)
    @@hasattr_py ||= Polyglot.eval('python', 'hasattr')
    @@hasattr_py.call(obj, name)
  end

  def len(obj)
    obj.__len__()
  end

  def sys
    @@sys ||= PyModuleWrapper.wrap(import_module('sys'))
  end

  def tuple(iterable=nil)
    @@tuple_py ||= Polyglot.eval('python', 'tuple')
    if iterable != nil
      PyCall::Tuple.new(*iterable)
    else
      Tuple.wrap(@@tuple_py.call)
    end
  end

  def same?(left, right)
    # todo update from upstream/master
  end

  def with(ctx)
    begin
      yield ctx.__enter__()
    rescue Exception => err
      # TODO: support telling what exception has been catched
      raise err unless ctx.__exit__(err.class, err, err.backtrace_locations)
    else
      ctx.__exit__(nil, nil, nil)
    end
  end

  require 'pycall/truffleruby/tuple'
  require 'pycall/truffleruby/list'
  require 'pycall/truffleruby/dict'
  require 'pycall/truffleruby/set'
  require 'pycall/truffleruby/slice'
end

#require 'pycall/iruby_helper_truffleruby' if defined? IRuby