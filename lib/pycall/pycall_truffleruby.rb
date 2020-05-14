module PyCall
  def self.import_module(name)
    Polyglot.eval('python', "import #{name}\n#{name}")
  end

  def builtins
    @builtins ||= wrap_module(LibPython::API.builtins_module_ptr)
  end

  def callable?(obj)

  end

  def dir(obj)

  end

  def eval(expr, globals: nil, locals: nil)
    Polyglot.eval('python', expr)
  end

  def exec(code, globals: nil, locals: nil)

  end

  def getattr(*args)

  end

  def hasattr?(obj, name)

  end

  def len(obj)

  end

  def sys

  end

  def tuple(iterable=nil)

  end

  def with(ctx)

  end
end