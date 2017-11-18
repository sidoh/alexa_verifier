require_relative '../spec_helper'

RSpec.describe AlexaRequestVerifier::InvalidCertificateError do
  it_behaves_like 'a StandardError'
end