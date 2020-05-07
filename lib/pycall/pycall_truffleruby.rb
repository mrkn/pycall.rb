module PyCall
  def self.import_module(name)
    Polyglot.eval('python', "import #{name}\n#{name}")
  end
end