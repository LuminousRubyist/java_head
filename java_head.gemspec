# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'java_head/version'

Gem::Specification.new do |spec|
  spec.name          = "java_head"
  spec.version       = JavaHead::VERSION
  spec.authors       = ["LuminousRubyist"]
  spec.email         = ["luminousrubyist@zoho.com"]
  spec.summary       = %q{Represent, compile, and run Java code in Ruby.}
  spec.description   = %q{JavaHead contains classes to represent Java packages and classes and to compile and execute them in Ruby. Use this in scripts to run Java programs from Ruby, or in IRB to develop Java in a sensible environment. Write simple code in both Java and Ruby and JavaHead will link them for you. }
  spec.homepage      = "https://github.com/LuminousRubyist/java_head"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0'
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "colorize", "~> 0.7.3"
  spec.add_development_dependency "minitest", "~> 5.4.3"
end
