require_relative '../spec_helper'

RSpec.describe AlexaRequestVerifier::InvalidRequestError do
  it_behaves_like 'a StandardError'
end