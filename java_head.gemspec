# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'java_head/version'

Gem::Specification.new do |spec|
  spec.name          = "java_head"
  spec.version       = JavaHead::VERSION
  spec.authors       = ["AndrewTLee"]
  spec.email         = ["andytaelee@gmail.com"]
  spec.summary       = %q{Represent, compile, and run Java code in Ruby.}
  spec.description   = %q{JavaHead contains classes to reprsent Java packages and classes and execute them in Ruby. Use this in scripts to run Java programs from Ruby, or in IRB to develop Java in a sensible environment}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
