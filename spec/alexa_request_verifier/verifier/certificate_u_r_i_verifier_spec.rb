require_relative '../../spec_helper'

RSpec.describe AlexaRequestVerifier::Verifier::CertificateURIVerifier do
  describe '#valid!' do
    context 'with a valid URI' do
      it 'returns true' do
        expect(subject.valid!('https://s3.amazonaws.com/echo.api/echo-api-cert-5.pem')).to eq(true)
      end

      context 'correctly normalises paths' do
        it 'returns true' do
          expect(subject.valid!('https://s3.amazonaws.com/echo.api/../echo.api/echo-api-cert-5.pem')).to eq(true)
        end
      end
    end

    context 'with an invalid URI' do
      context 'that is not a URI' do
        it 'raises the expected error' do
          expect{
            subject.valid!('<html>')
          }.to raise_error(AlexaRequestVerifier::InvalidCertificateURIError, 'Invalid certificate URI : <html> : bad URI(is not URI?): <html>.')
        end
      end

      context 'that is not HTTPS' do
        it 'raises the expected error' do
          expect{
            subject.valid!('http://example.com')
          }.to raise_error(AlexaRequestVerifier::InvalidCertificateURIError, "Invalid certificate URI : URI scheme must be 'https'. Got: 'http'.")
        end
      end

      context 'that is not on port 443' do
        it 'raises the expected error' do
          expect {
            subject.valid!('https://example.com:80')
          }.to raise_error(AlexaRequestVerifier::InvalidCertificateURIError, "Invalid certificate URI : URI port must be '443'. Got: '80'.")
        end
      end

      context 'that is not from the expected host' do
        it 'raises the expected error' do
          expect{
            subject.valid!('https://example.com')
          }.to raise_error(AlexaRequestVerifier::InvalidCertificateURIError, "Invalid certificate URI : URI host must be 's3.amazonaws.com'. Got: 'example.com'.")
        end
      end

      context 'that is not in the correct path' do
        it 'raises the expected error' do
          expect{
            subject.valid!('https://s3.amazonaws.com/Echo.APi/foo')
          }.to raise_error(AlexaRequestVerifier::InvalidCertificateURIError, "Invalid certificate URI : URI path must start with '/echo.api/'. Got: '/Echo.APi/foo'.")
        end
      end
    end
  end

  describe '#valid?' do
    context 'with a valid URI' do
      it 'returns true' do
        expect(subject.valid?('https://s3.amazonaws.com/echo.api/echo-api-cert-5.pem')).to eq(true)
      end

      context 'correctly normalises paths' do
        it 'returns true' do
          expect(subject.valid?('https://s3.amazonaws.com/echo.api/../echo.api/echo-api-cert.pem')).to eq(true)
        end
      end
    end

    context 'with an invalid URI' do
      context 'that is not HTTPS' do
        it 'returns false' do
          expect(subject.valid?('http://example.com')).to eq(false)
        end
      end

      context 'that is not on port 443' do
        it 'returns false' do
          expect(subject.valid?('https://example.com:80')).to eq(false)
        end
      end

      context 'that is not from the expected host' do
        it 'returns false' do
          expect(subject.valid?('https://example.com')).to eq(false)
        end
      end

      context 'that is not in the correct path' do
        it 'returns false' do
          expect(subject.valid?('https://s3.amazonaws.com/Echo.APi/foo')).to eq(false)
        end
      end
    end
  end
end