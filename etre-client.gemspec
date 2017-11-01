# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'etre-client/version'

Gem::Specification.new do |spec|
  spec.name          = 'etre-client'
  spec.version       = Etre::Client::VERSION
  spec.license       = 'Apache-2.0'
  spec.authors       = ['Michael Finch']
  spec.email         = ['mfinch@squareup.com']
  spec.summary       = 'Client gem for interacting with Etre'
  spec.homepage      = 'https://github.com/square/etre-client-ruby'
  spec.required_ruby_version = '>= 2.3.0'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'json'
  spec.add_runtime_dependency 'rest-client', '~> 2.0'

  spec.add_development_dependency 'rake', '~> 12.2', '>= 12.2.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
