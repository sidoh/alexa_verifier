require_relative '../spec_helper'

RSpec.describe AlexaRequestVerifier::InvalidCertificateURIError do
  describe '#initializer' do
    context 'without a value attribute' do
      it 'creates the expected message' do
        expect(AlexaRequestVerifier::InvalidCertificateURIError.new('Test Message').message).to eq('Invalid certificate URI : Test Message.')
      end
    end

    context 'with a value attribute' do
      it 'creates the expected message' do
        expect(AlexaRequestVerifier::InvalidCertificateURIError.new('Test Message', 'Foo').message).to eq("Invalid certificate URI : Test Message. Got: 'Foo'.")
      end
    end
  end
end