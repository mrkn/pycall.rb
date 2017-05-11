# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pycall/version'

Gem::Specification.new do |spec|
  spec.name          = "pycall"
  spec.version       = PyCall::VERSION
  spec.authors       = ["Kenta Murata"]
  spec.email         = ["mrkn@mrkn.jp"]

  spec.summary       = %q{pycall}
  spec.description   = %q{pycall}
  spec.homepage      = "https://github.com/mrkn/pycall"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    case f
    when %r{^Guardfile},  # NOTE: Skip symlink for Windows
         %r{^(test|spec|features)/}
      true
    else
      false
    end
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi"

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "launchy"
  spec.add_development_dependency "pry"
end
