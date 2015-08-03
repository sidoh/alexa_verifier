# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'alexa_verifier'

Gem::Specification.new do |spec|
  spec.name          = "alexa_verifier"
  spec.version       = AlexaVerifier::VERSION
  spec.authors       = ["Christopher Mullins"]
  spec.email         = ["chris@sidoh.org"]

  spec.summary       = %q{Verifies requests sent to an Alexa skill are sent from Amazon}
  spec.homepage      = "http://www.github.com/sidoh/alexa_verifier"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "curb", "~> 0.7.16"
  spec.add_development_dependency "webmock"
end
