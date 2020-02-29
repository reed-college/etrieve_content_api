
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'etrieve_content_api/version'

Gem::Specification.new do |spec|
  spec.name          = 'etrieve_content_api'
  spec.version       = EtrieveContentApi::Version::VERSION
  spec.authors       = ['Shannon Henderson']

  spec.summary       = 'A Ruby wrapper for the Etrieve Content API'
  spec.description   = "Interact with Etrieve Content's REST API"
  spec.homepage      = 'https://github.com/reed-college/etrieve_content_api'
  spec.license       = 'BSD-3-Clause'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = 'exe'
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'json'
  spec.add_runtime_dependency 'rest-client'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'webmock'

  spec.required_ruby_version = '>= 2.1.0'
end
