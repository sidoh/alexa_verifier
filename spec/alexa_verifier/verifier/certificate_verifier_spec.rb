require_relative '../../spec_helper'

RSpec.describe AlexaVerifier::Verifier::CertificateVerifier, vcr: true do
  let(:valid_certificate) do
    certificate, _ = AlexaVerifier::CertificateStore.fetch('https://s3.amazonaws.com/echo.api/echo-api-cert-5.pem')

    certificate
  end

  let(:valid_chain) do
    _, chain = AlexaVerifier::CertificateStore.fetch('https://s3.amazonaws.com/echo.api/echo-api-cert-5.pem')

    chain
  end

  let(:invalid_certificate) do
    modified_certificate = valid_certificate

    modified_certificate_extensions = valid_certificate.extensions
    modified_certificate_extensions.delete_at(0) # Remove the SAN extension

    modified_certificate.extensions = modified_certificate_extensions

    modified_certificate
  end

  let(:invalid_chain) { [] }

  before :each do
    Timecop.freeze(Time.local(2017,11,20,10,57,19))
  end

  after :each do
    Timecop.return
  end

  describe '#valid!' do
    context 'with a valid certificate' do
      it 'returns true' do
        expect(subject.valid!(valid_certificate, valid_chain)).to eq(true)
      end
    end

    context 'with an invalid certificate' do
      context 'that is not valid yet' do
        before :each do
          Timecop.freeze(Time.local(2015,01,01))
        end

        it 'raises a AlexaVerifier::InvalidCertificateError' do
          expect{
            subject.valid!(valid_certificate, valid_chain)
          }.to raise_error(AlexaVerifier::InvalidCertificateError, 'Certificate is not in date.')
        end
      end

      context 'that is out of date' do
        before :each do
          Timecop.freeze(Time.local(2020,01,01))
        end

        it 'raises a AlexaVerifier::InvalidCertificateError' do
          expect{
            subject.valid!(valid_certificate, valid_chain)
          }.to raise_error(AlexaVerifier::InvalidCertificateError, 'Certificate is not in date.')
        end
      end

      context 'that does not contain the requires SAN' do
        it 'raises a AlexaVerifier::InvalidCertificateError' do
          expect{
            subject.valid!(invalid_certificate, valid_chain)
          }.to raise_error(AlexaVerifier::InvalidCertificateError, 'Certificate does not contain SAN: echo-api.amazon.com.')
        end
      end

      context 'that does not create a chain of trust' do
        it 'raises a AlexaVerifier::InvalidCertificateError' do
          expect{
            subject.valid!(valid_certificate, invalid_chain)
          }.to raise_error(AlexaVerifier::InvalidCertificateError, "Unable to create a 'chain of trust' from the provided certificate to a trusted root CA.")
        end
      end
    end
  end

  describe '#valid?' do
    context 'with a valid certificate and chain' do
      it 'returns true' do
        expect(subject.valid?(valid_certificate, valid_chain)).to eq(true)
      end
    end

    context 'with an invalid certificate or chain' do
      context 'that is not valid yet' do
        before :each do
          Timecop.freeze(Time.local(2015,01,01))
        end

        it 'returns false' do
          expect(subject.valid?(valid_certificate, valid_chain)).to eq(false)
        end
      end

      context 'that is out of date' do
        before :each do
          Timecop.freeze(Time.local(2020,01,01))
        end

        it 'returns false' do
          expect(subject.valid?(valid_certificate, valid_chain)).to eq(false)
        end
      end

      context 'that does not contain the requires SAN' do
        it 'returns false' do
          expect(subject.valid?(invalid_certificate, valid_chain)).to eq(false)
        end
      end

      context 'that does not create a chain of trust' do
        it 'returns false' do
          expect(subject.valid?(valid_certificate, invalid_chain)).to eq(false)
        end
      end
    end
  end
end
