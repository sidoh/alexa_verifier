require_relative '../spec_helper'

RSpec.describe AlexaRequestVerifier::Verifier, vcr: true do
  it_behaves_like 'a verifier object', AlexaRequestVerifier::Verifier.new
end
