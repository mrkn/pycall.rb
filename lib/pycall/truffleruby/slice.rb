module PyCall
  class Slice < PyObjectWrapper

    def initialize(*args)
      @@slice_class = Polyglot.eval("python", "slice")
      if args.length == 1 && args[0].is_a?(Integer)#handle special spec case from PyCall
        #How does this make sense?
        args = [nil, args[0]]
      end
      unwrapped = PyObjectWrapper.unwrap(args)
      super @@slice_class.call(*unwrapped)
    end

    def self.all
      @@slice_class = Polyglot.eval("python", "slice")
      super @@slice_class.call(PyCall::LibPython::API::None.__pyptr__)
    end
  end

  Conversion.register_python_type_mapping(Slice.new(nil).__pyptr__, Slice)
end
