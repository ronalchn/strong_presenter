# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'strong_presenter/version'

Gem::Specification.new do |gem|
  gem.name          = "strong_presenter"
  gem.version       = StrongPresenter::VERSION
  gem.authors       = ["Ronald Chan"]
  gem.email         = ["ronalchn@gmail.com"]
  gem.description   = %q{strong_presenter adds a layer of presentation logic to your application, and gives you strong_parameters-like logic to determine which attributes are visible}
  gem.summary       = %q{strong_presenter adds a layer of presentation logic to your application, and gives you strong_parameters-like logic to determine which attributes are visible}
  gem.homepage      = "https://github.com/ronalchn/strong_presenter"
  gem.license       = "MPLv2"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'activesupport', '>= 3.0'
  gem.add_dependency 'actionpack', '>= 3.0'
  gem.add_dependency 'request_store', '~> 1.0.3'
  gem.add_dependency 'activemodel', '>= 3.0'
  gem.add_dependency 'strong_attributes', '~> 0.0.2'

  gem.add_development_dependency 'ammeter'
  gem.add_development_dependency 'rake', '>= 0.9.2'
  gem.add_development_dependency 'rspec', '~> 2.12'
  gem.add_development_dependency 'rspec-mocks', '>= 2.12.1'
  gem.add_development_dependency 'rspec-rails', '~> 2.12'
  gem.add_development_dependency 'minitest-rails', '~> 0.2'
  gem.add_development_dependency 'capybara'
  gem.add_development_dependency 'active_model_serializers'
  gem.add_development_dependency 'activerecord', '>= 3.0'
end
