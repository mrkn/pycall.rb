# PyCall -- Calling Python functions from the Ruby language

[![Build Status](https://travis-ci.org/mrkn/pycall.svg?branch=master)](https://travis-ci.org/mrkn/pycall)
[![Build status](https://ci.appveyor.com/api/projects/status/071is0f4iu0vy8lp/branch/master?svg=true)](https://ci.appveyor.com/project/mrkn/pycall/branch/master)

This library provides the features to directly call and partially interoperate with Python from the Ruby language.  You can import arbitrary Python modules into Ruby modules, call Python functions with automatic type conversion from Ruby to Python.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pycall'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install --pre pycall

## Usage

Here is a simple example to call Python's `math.sin` function and compare it to the `Math.sin` in Ruby:

    require 'pycall/import'
    include PyCall::Import
    pyimport :math
    math.sin.(math.pi / 4) - Math.sin(Math::PI / 4)   # => 0.0
    #       ^ This period is necessary

Type conversions from Ruby to Python are automatically performed for numeric, boolean, string, arrays, and hashes.

### Python function call

In this version of pycall, the all of functions and methods in Python is wrapped as callable objects in Ruby.  It means we need to put a priod between the name of function and `(` like `math.sin.(...)` in the above example.

This unnatural notation is a temporary specification, so we should be able to write `math.sin(...)` in the future.

## Wrapping Python classes

Using `PyCall::PyObjectWrapper` module, we can create incarnation classes for Python classes in Ruby language.  For example, the following script defines a incarnation class for `numpy.ndarray` class.

```ruby
require 'pycall'

class Ndarray
  import PyCall::PyObjectWrapper
  wrap_class PyCall.import_module('numpy').ndarray
end
```

Defineing incarnation classes using `wrap_class` registeres automatic type conversion, so it changes the class of wrapper object.  For example:

    require 'pycall/import'
    include PyCall::Import
    pyimport :numpy, as: :np
    x1 = np.array(PyCall.tuple(10))
    x1.class   # => PyCall::PyObject

    class Ndarray
      import PyCall::PyObjectWrapper
      wrap_class PyCall.import_module('numpy').ndarray
      # NOTE: From here, numpy.ndarray objects are converted to Ndarray objects
    end

    x2 = np.array(PyCall.tuple(10))
    x2.class   # => Ndarray


**NOTE: Currently I'm trying to rewrite class wrapping system, so the content of this section will be changed.**

**NOTE: I will write an efficient wrapper for numpy by RubyKaigi 2017.**

### Specifying the Python version

If you want to use a specific version of Python instead of the default, you can change the Python version by setting the `PYTHON` environment variable to the path of the `python` executable.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mrkn/pycall.


## Acknowledgement

[PyCall.jl](https://github.com/JuliaPy/PyCall.jl) is referred too many times to implement this library.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

