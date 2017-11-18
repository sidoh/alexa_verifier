require_relative '../../spec_helper'

RSpec.describe AlexaRequestVerifier::Verifier::CertificateVerifier do
  let(:valid_certificate) do
    file = File.open('./spec/fixtures/echo-api-cert.pem', 'rb')
    certificate_data = file.read
    file.close

    OpenSSL::X509::Certificate.new(certificate_data)
  end

  let(:invalid_certificate) do
    modified_certificate = valid_certificate

    modified_certificate_extensions = valid_certificate.extensions
    modified_certificate_extensions.delete_at(0) # Remove the SAN extension

    modified_certificate.extensions = modified_certificate_extensions

    modified_certificate
  end

  before :each do
    Timecop.freeze(Time.local(2017,11,20,10,57,19))
  end

  after :each do
    Timecop.return
  end

  describe '#valid!' do
    context 'with a valid certificate' do
      it 'returns true' do
        expect(subject.valid!(valid_certificate)).to eq(true)
      end
    end

    context 'with an invalid certificate' do
      context 'that is not valid yet' do
        before :each do
          Timecop.freeze(Time.local(2015,01,01))
        end

        it 'raises a AlexaRequestVerifier::InvalidCertificateError' do
          expect{
            subject.valid!(valid_certificate)
          }.to raise_error(AlexaRequestVerifier::InvalidCertificateError, 'Certificate is not in date.')
        end
      end

      context 'that is out of date' do
        before :each do
          Timecop.freeze(Time.local(2020,01,01))
        end

        it 'raises a AlexaRequestVerifier::InvalidCertificateError' do
          expect{
            subject.valid!(valid_certificate)
          }.to raise_error(AlexaRequestVerifier::InvalidCertificateError, 'Certificate is not in date.')
        end
      end

      context 'that does not contain the requires SAN' do
        it 'raises a AlexaRequestVerifier::InvalidCertificateError' do
          expect{
            subject.valid!(invalid_certificate)
          }.to raise_error(AlexaRequestVerifier::InvalidCertificateError, 'Certificate does not contain SAN: echo-api.amazon.com.')
        end
      end

      context 'that does not create a chain of trust' do
        it 'raises a AlexaRequestVerifier::InvalidCertificateError'
      end
    end
  end

  describe '#valid?' do
    context 'with a valid certificate' do
      it 'returns true' do
        expect(subject.valid?(valid_certificate)).to eq(true)
      end
    end

    context 'with an invalid certificate' do
      context 'that is not valid yet' do
        before :each do
          Timecop.freeze(Time.local(2015,01,01))
        end

        it 'returns false' do
          expect(subject.valid?(valid_certificate)).to eq(false)
        end
      end

      context 'that is out of date' do
        before :each do
          Timecop.freeze(Time.local(2020,01,01))
        end

        it 'returns false' do
          expect(subject.valid?(valid_certificate)).to eq(false)
        end
      end

      context 'that does not contain the requires SAN' do
        it 'returns false' do
          expect(subject.valid?(invalid_certificate)).to eq(false)
        end
      end

      context 'that does not create a chain of trust' do
        it 'returns false'
      end
    end
  end
end
