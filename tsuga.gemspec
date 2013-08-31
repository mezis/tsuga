# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tsuga/version'

Gem::Specification.new do |spec|
  spec.name          = "tsuga"
  spec.version       = Tsuga::VERSION
  spec.authors       = ["Julien Letessier"]
  spec.email         = ["julien.letessier@gmail.com"]
  spec.description   = %q{Hierarchical Geo Clusterer tuned for Google Maps usage}
  spec.summary       = %q{Hierarchical Geo Clusterer tuned for Google Maps usage}
  spec.homepage      = "http://github.com/mezis/tsuga"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-nav"
end
