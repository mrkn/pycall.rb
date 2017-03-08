module PyCall
  class PyObject
    include PyObjectWrapper

    def self.null
      new(LibPython::PyObjectStruct.new(FFI::Pointer::NULL))
    end
  end

  def self.getattr(pyobj, name, default=nil)
    name = check_attr_name(name)
    pyobj = pyobj.__pyobj__ unless pyobj.kind_of? LibPython::PyObjectStruct
    value = LibPython.PyObject_GetAttrString(pyobj, name)
    if value.null?
      return default if default
      raise PyError.fetch
    end
    value.to_ruby
  end

  def self.setattr(pyobj, name, value)
    name = check_attr_name(name)
    value = Conversions.from_ruby(value)
    value = value.__pyobj__ unless pyobj.kind_of? LibPython::PyObjectStruct
    pyobj = pyobj.__pyobj__ unless pyobj.kind_of? LibPython::PyObjectStruct
    return self unless LibPython.PyObject_SetAttrString(pyobj, name, value) == -1
    raise PyError.fetch
  end

  def self.hasattr?(pyobj, name)
    name = check_attr_name(name)
    pyobj = pyobj.__pyobj__ unless pyobj.kind_of? LibPython::PyObjectStruct
    1 == LibPython.PyObject_HasAttrString(pyobj, name)
  end

  def self.check_attr_name(name)
    return name.to_str if name.respond_to? :to_str
    return name.to_s if name.kind_of? Symbol
    raise TypeError, "attribute name must be a String or a Symbol: #{name.inspect}"
  end
  private_class_method :check_attr_name

  def self.getitem(pyobj, key)
    pyobj = pyobj.__pyobj__ unless pyobj.kind_of? LibPython::PyObjectStruct
    pykey = Conversions.from_ruby(key)
    value = LibPython.PyObject_GetItem(pyobj, pykey)
    return value.to_ruby unless value.null?
    raise PyError.fetch
  end

  def self.setitem(pyobj, key, value)
    pyobj = pyobj.__pyobj__ unless pyobj.kind_of? LibPython::PyObjectStruct
    pykey = Conversions.from_ruby(key)
    value = Conversions.from_ruby(value)
    return self unless LibPython.PyObject_SetItem(pyobj, pykey, value) == -1
    raise PyError.fetch
  end
end
