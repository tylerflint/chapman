# -*- encoding: utf-8 -*-
require File.expand_path('../lib/chapman/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Tyler Flint"]
  gem.email         = ["tylerflint@gmail.com"]
  gem.description   = %q{Like stalker, but can stalk concurrently}
  gem.summary       = %q{Takes the concept of stalker and introduces a thread pool. It's great for scenarios where tasks are light and mostly IO bound.}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "chapman"
  gem.require_paths = ["lib"]
  gem.version       = Chapman::VERSION
end
