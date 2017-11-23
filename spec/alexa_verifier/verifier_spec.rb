require_relative '../spec_helper'

RSpec.describe AlexaVerifier::Verifier, vcr: true do
  it_behaves_like 'a verifier object', AlexaVerifier::Verifier.new
end
