require_relative '../spec_helper'

RSpec.describe AlexaVerifier::InvalidCertificateError do
  it_behaves_like 'a StandardError'
end