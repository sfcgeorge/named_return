# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "named_return/version"

Gem::Specification.new do |spec|
  spec.name          = "named_return"
  spec.version       = NamedReturn::VERSION
  spec.authors       = ["Simon George"]
  spec.email         = ["simon@sfcgeorge.co.uk"]

  spec.summary       = "Named return paths using `throw` and DSL around catch"
  spec.description   = "Named return paths using `throw` and DSL around catch"
  spec.homepage      = "https://www.sfcgeorge.co.uk/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
