require_relative '../spec_helper'

RSpec.describe AlexaVerifier::InvalidRequestError do
  it_behaves_like 'a StandardError'
end