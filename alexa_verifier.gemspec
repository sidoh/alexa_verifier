lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'alexa_verifier/version'

Gem::Specification.new do |spec|
  spec.name          = 'alexa_verifier'
  spec.version       = AlexaVerifier::VERSION
  spec.authors       = ['Christopher Mullins', 'Matt Rayner']
  spec.email         = %w[chris@sidoh.org m@rayner.io]

  spec.summary       = 'Verify HTTP requests sent to an Alexa skill are sent from Amazon.'
  spec.description   = 'This gem is designed to work with Rack applications that serve as back-ends for Amazon Alexa skills.'
  spec.homepage      = 'https://github.com/sidoh/alexa_verifier'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'coveralls', '~> 0.8.21'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.14'
  spec.add_development_dependency 'timecop', '~> 0.9'
  spec.add_development_dependency 'vcr', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 3.0'
end
