require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
]
SimpleCov.start

require 'bundler/setup'
require 'vcr'
require 'webmock/rspec'
require 'timecop'
require 'alexa_request_verifier'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Load support files
  Dir['./spec/support/**/*.rb'].each {|f| require f}

  # Clean up any potential certificate caching
  config.after(:each) do
    AlexaRequestVerifier::CertificateStore.instance_variable_set(:@store, nil)
  end
end

VCR.configure do |config|
  config.cassette_library_dir = './spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
end
