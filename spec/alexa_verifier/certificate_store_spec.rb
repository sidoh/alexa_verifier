require_relative '../spec_helper'

RSpec.describe AlexaVerifier::CertificateStore, vcr: true do
  after :each do
    subject.instance_variable_set(:@store, nil)
  end

  describe '#fetch' do
    let(:uri) { 'https://s3.amazonaws.com/echo.api/echo-api-cert-5.pem' }

    before :each do
      Timecop.freeze(Time.local(2017,11,19,00,13,37))
    end

    after :each do
      Timecop.return
    end

    context 'with a new certificate uri' do
      it 'downloads the certificate' do
        subject.fetch(uri)
        expect(a_request(:get, uri)).to have_been_made.times(1)
      end

      it 'adds a new entry to our store' do
        expect{subject.fetch(uri)}.to change{subject.store.length}.from(0).to(1)
      end

      it 'returns a certificate file' do
        cert, _ = subject.fetch(uri)
        expect(cert).to be_a(OpenSSL::X509::Certificate)
      end

      it 'returns a certificate chain' do
        _, chain = subject.fetch(uri)
        expect(chain).to be_a(Array)
        expect(chain.length).to eq(1)
      end

      context 'new entry' do
        before :each do
          subject.fetch(uri)
        end

        it 'has the expected timestamp' do
          expect(subject.store[uri][:timestamp]).to eq(Time.local(2017,11,19,00,13,37))
        end

        it 'has a certificate as expected' do
          expect(subject.store[uri][:certificate]).to be_a(OpenSSL::X509::Certificate)
        end

        it 'has a chain as expected' do
          expect(subject.store[uri][:chain]).to be_a(Array)
          expect(subject.store[uri][:chain].first).to be_a(OpenSSL::X509::Certificate)
        end
      end

      context 'when an error occurs whilst downloading certificate' do
        before :each do
          stub_request(:get, uri).
              to_return(status: [500, 'Internal Server Error'])
        end

        it 'raises AlexaVerifier::InvalidCertificateError' do
          expect{
            subject.fetch(uri)
          }.to raise_error(AlexaVerifier::InvalidCertificateError, 'Unable to download certificate from https://s3.amazonaws.com/echo.api/echo-api-cert-5.pem - Got 500 status code')
        end
      end
    end

    context 'with an existing certificate uri' do
      before :each do
        subject.instance_variable_set(:@store, { "#{uri}" => { timestamp: Time.now, certificate: OpenSSL::X509::Certificate.new } })
      end

      context 'that is still within the cache time limit' do
        before :each do
          Timecop.freeze(Time.local(2017,11,19,00,13,37) + (subject::CERTIFICATE_CACHE_TIME - 100))
        end

        it 'does not download the certificate' do
          subject.fetch(uri)
          expect(a_request(:get, uri)).not_to have_been_made
        end

        it 'does not add an entry to the store' do
          expect{subject.fetch(uri)}.not_to change{subject.store.length}
        end

        it 'returns a certificate file' do
          cert, _ = subject.fetch(uri)
          expect(cert).to be_a(OpenSSL::X509::Certificate)
        end
      end

      context 'that is outside the cache time limit' do
        before :each do
          Timecop.freeze(Time.local(2017,11,19,00,13,37) + (subject::CERTIFICATE_CACHE_TIME + 100))
        end

        it 'downloads the certificate' do
          subject.fetch(uri)
          expect(a_request(:get, uri)).to have_been_made.times(1)
        end

        it 'does not change the certificate count' do
          expect{subject.fetch(uri)}.not_to change{subject.store.length}
        end

        it 'updates the entry\'s timestamp' do
          expect{subject.fetch(uri)}.to change{subject.store[uri][:timestamp]}
        end

        it 'returns a certificate file' do
          cert, _ = subject.fetch(uri)

          expect(cert).to be_a(OpenSSL::X509::Certificate)
        end
      end
    end
  end

  describe '#delete' do
    context 'with an existing entry' do
      before :each do
        subject.instance_variable_set(:@store, { 'http://example.com' => { foo: 'bar' } })
      end

      it 'returns the deleted entry' do
        expect(subject.delete('http://example.com')).to eq({ foo: 'bar' })
      end
    end

    context 'without an existing entry' do
      before :each do
        subject.instance_variable_set(:@store, nil)
      end

      it 'returns nil' do
        expect(subject.delete('http://example.com')).to eq(nil)
      end
    end
  end

  describe '#store' do
    context 'with no store' do
      before :each do
        subject.instance_variable_set(:@store, nil)
      end

      it 'returns an empty hash' do
        expect(subject.store).to eq({})
      end
    end

    context 'with an existing store' do
      before :each do
        subject.instance_variable_set(:@store, { 'http://example.com' => { foo: 'bar' } })
      end

      it 'returns the store' do
        expect(subject.store).to eq({ 'http://example.com' => { foo: 'bar' } })
      end
    end
  end
end