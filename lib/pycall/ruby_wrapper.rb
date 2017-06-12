require 'pycall'

module PyCall
  class RubyWrapStruct < LibPython::PyObjectStruct
      layout ob_refcnt:    :ssize_t,
             ob_type:      LibPython::PyTypeObjectStruct.by_ref,
             rb_object_id: :ssize_t
  end

  # This will be called from __initialize_pycall__ defined in pycall/init.rb
  private_class_method def self.__initialize_ruby_wrapper__()
    @ruby_wrapper_members = FFI::MemoryPointer.new(LibPython::PyMemberDef.size, 2)
    LibPython::PyMemberDef.new(@ruby_wrapper_members).tap do |member|
      member.name     = 'rb_object_id'
      member[:type]   = LibPython::T_PYSSIZET
      member[:offset] = LibPython::PyObjectStruct.size
      member[:flags]  = RubyWrapStruct.offset_of(:rb_object_id)
      member.doc      = "Ruby object ID"
    end
    @ruby_wrapper_dealloc = FFI::Function.new(:void, [LibPython::PyObjectStruct.ptr]) do |pyptr|
      GCGuard.unregister(pyptr)
      nil
    end
    @ruby_wrapper_repr = FFI::Function.new(LibPython::PyObjectStruct.ptr, [LibPython::PyObjectStruct.ptr]) do |pyptr|
      str = if pyptr.null?
              '<PyCall.ruby_wrapper NULL>'
            else
              obj = ObjectSpace._id2ref(RubyWrapStruct.new(pyptr.pointer)[:rb_object_id])
              "<PyCall.ruby_wrapper #{obj.inspect}>"
            end
      Conversions.from_ruby(str)
    end
    @ruby_wrapper_hash = FFI::Function.new(:uint64, [LibPython::PyObjectStruct.ptr]) do |pyptr|
      h = ObjectSpace._id2ref(RubyWrapStruct.new(pyptr.pointer)[:rb_object_id]).hash
      h == -1 ? PyCall::HASH_SALT : h
    end
    pysalt32 = 0xb592cd9b # This value comes from PyCall.jl
    @ruby_wrapper_hash32 = FFI::Function.new(:uint32, [LibPython::PyObjectStruct.ptr]) do |pyptr|
      # int64to32hash from src/support/hashing.c in julia
      key = ObjectSpace._id2ref(RubyWrapStruct.new(pyptr.pointer)[:rb_object_id]).hash
      key = (~key) + (key << 18)
      key =   key  ^ (key >> 31)
      key = key * 21
      key = key ^ (key >> 11)
      key = key + (key << 6)
      key = key ^ (key >> 22)
      h = 0xFFFFFFFF & key
      h == -1 ? pysalt32 : h
    end
    @ruby_callable_call = FFI::Function.new(
      LibPython::PyObjectStruct.ptr,
      [LibPython::PyObjectStruct.ptr, LibPython::PyObjectStruct.ptr, LibPython::PyObjectStruct.ptr]
    ) do |self_, args_, kwargs_|
      obj = ObjectSpace._id2ref(RubyWrapStruct.new(self_.pointer)[:rb_object_id])
      begin
        args = Conversions.to_ruby(args_).to_ary
        if kwargs_.null?
          ret = obj.(*args)
        else
          kwargs = PyCall::Dict.new(kwargs_).to_hash
          ret = obj.(*args, **kwargs)
        end
        Conversions.from_ruby(ret)
      rescue Exception => err
        PyCall.raise_python_exception(err)
        LibPython::PyObjectStruct.null
      end
    end
    @ruby_callable_getattr = FFI::Function.new(
      LibPython::PyObjectStruct.ptr,
      [LibPython::PyObjectStruct.ptr, LibPython::PyObjectStruct.ptr]
    ) do |self_, attr_|
      obj = ObjectSpace._id2ref(RubyWrapStruct.new(self_.pointer)[:rb_object_id])
      attr = Conversions.to_ruby(attr_)
      begin
        case attr
        when '__name__', 'func_name'
          if obj.respond_to? :name
            Conversions.from_ruby(obj.name)
          else
            Conversions.from_ruby(obj.to_s)
          end
        when '__doc__', 'func_doc'
          # TODO: support docstring
          PyCall.none
        when '__module__', '__defaults__', 'func_defaults', '__closure__', 'func_closure'
          PyCall.none
        else
          # TODO: handle __code__ and func_code
          LibPython.PyObject_GenericGetAttr(self_, attr_)
        end
      rescue Exception => err
        PyCall.raise_python_exception(err)
        LibPython::PyObjectStruct.null
      end
    end
    @ruby_wrapper = LibPython::PyTypeObjectStruct.new("PyCall.ruby_wrapper", RubyWrapStruct.size) do |t|
      t[:tp_flags] |= LibPython::Py_TPFLAGS_BASETYPE
      t[:tp_members] = LibPython::PyMemberDef.new(@ruby_wrapper_members)
      t[:tp_dealloc] = @ruby_wrapper_dealloc
      t[:tp_repr] = @ruby_wrapper_repr
      if FFI.type_size(LibPython.find_type(:Py_hash_t)) < FFI.type_size(:uint64)
        t[:tp_hash] = @ruby_wrapper_hash32
      else
        t[:tp_hash] = @ruby_wrapper_hash
      end
    end
    @ruby_callable = PyCall.ruby_wrapper_subclass_new("PyCall.ruby_callable") do |t|
      t[:tp_call] = @ruby_callable_call
      t[:tp_getattro] = @ruby_callable_getattr
    end
  end

  def self.ruby_wrapper_subclass_new(name)
    LibPython::PyTypeObjectStruct.new(name, RubyWrapStruct.size + FFI.type_size(:pointer)) do |t|
      t[:tp_base] = @ruby_wrapper.pointer
      LibPython.Py_IncRef(LibPython::PyObjectStruct.new(@ruby_wrapper.pointer))
      yield(t)
    end
  end

  def self.ruby_wrapper_new(type, obj)
    pyobj = LibPython._PyObject_New(type)
    p rw_refcnt: pyobj[:ob_refcnt]
    RubyWrapStruct.new(pyobj.pointer).tap do |rw|
      rw[:rb_object_id] = obj.object_id
      GCGuard.register(rw, obj)
    end
  end

  def self.wrap_ruby_object(obj)
    ruby_wrapper_new(@ruby_wrapper, obj)
  end

  def self.wrap_ruby_callable(obj)
    ruby_wrapper_new(@ruby_callable, obj)
  end
end
