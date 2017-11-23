RSpec.shared_examples 'a StandardError' do
  it 'behaves like a StandardError' do
    error = described_class.new('foo')
    expect(error.message).to eq('foo')
  end
end

RSpec.shared_examples 'it has configuration options' do |attributes|
  attributes.each do |attribute|
    describe "##{attribute.to_s}?" do
      context "with ##{attribute} set to false" do
        let(:instance) do
          instance = described_class.new
          instance.send("#{attribute}=".to_sym, false)

          instance
        end

        it 'answers with false' do
          expect(instance.send("#{attribute}?".to_sym)).to eq(false)
        end
      end

      context "with ##{attribute} set to true" do
        let(:instance) do
          instance = described_class.new
          instance.send("#{attribute}=".to_sym, true)

          instance
        end

        it 'answers with true' do
          expect(instance.send("#{attribute}?".to_sym)).to eq(true)
        end
      end
    end
  end
end

RSpec.shared_examples 'a verifier object' do |subject|
  # Setup requests for testing
  before :each do
    Timecop.freeze(Time.local(2017,11,20,8,45,05))
  end

  after :each do
    Timecop.return
  end

  let(:valid_env) { { "HTTP_SIGNATURECERTCHAINURL" => 'https://s3.amazonaws.com/echo.api/echo-api-cert-5.pem', "HTTP_SIGNATURE" => "jJsLfPdMlcILlbOpGR2PLbJyb+CJrsAHgATg34UB5zyCYkHqRJvNDlJmxHar76B10Bk7UFJOWue4Fo772W0/cVJREK3HdqLnUNvJ9Yn2gs9ZLZQKQHFDysvo+0bKXA60Fi7RyF/O21m5i/u+LJlhNs3pkiOSUgXUmbST2cECpkG5yZWch7sgl8EEjk94FUy1s7gfCdT2Y4f4UGafQ5CJNtuEXCCaw0uu9NOY/RGBY1Gv+COmTlppvFLtFNqRbl9tJ7nSF44fcSIEPdJHoVDQ7FxdsbZopoZbsApNTHXXQun3+HuPYZG2kwiZ5Bt2z5F8WhbsdaplAB6CUltHVRsngQ==" } }
  let(:valid_body) { double(:body, read: " {\"session\": \n{\"sessionId\":\"SessionId.1cfa16c1-9794-4e44-9358-a009f0a6ea1c\",\"application\":{\"applicationId\":\"amzn1.ask.skill.f5e6173c-8f7a-4c51-85e8-275e52d9443b\"},\"attributes\":{},\"user\":{\"userId\":\"amzn1.ask.account.AFLKBJN4MUE2INQZPMXA2EQFB7ABENF646BL4526SWH7DQNKBVANCPKU4SMWN7ZJEOWIN3RSTZ3L2IJBDGBICRWVBADLN62UB6HNWA4VK2MCZD3DCNOZ6USQDZZSQFD2GRKUC4V5YWPYXJFILKLVEA7IJB2MY4ILWEJ3TC6MG7VQVFHK7PE6VH5KT2QUPWH4KPYOT6EY4DDWEBY\",\"accessToken\":null},\"new\":true},\n\"request\":\n{\"intent\":{\"name\":\"PlayAudio\",\"slots\":{}},\"requestId\":\"EdwRequestId.edb164fe-5dd1-4fb1-984b-bba5f0d2ee6d\",\"type\":\"IntentRequest\",\"locale\":\"en-GB\",\"timestamp\":\"2017-11-20T08:45:02Z\"},\"context\":{\"AudioPlayer\":{\"playerActivity\":\"IDLE\"},\"System\":{\"application\":{\"applicationId\":\"amzn1.ask.skill.f5e6173c-8f7a-4c51-85e8-275e52d9443b\"},\"user\":{\"userId\":\"amzn1.ask.account.AFLKBJN4MUE2INQZPMXA2EQFB7ABENF646BL4526SWH7DQNKBVANCPKU4SMWN7ZJEOWIN3RSTZ3L2IJBDGBICRWVBADLN62UB6HNWA4VK2MCZD3DCNOZ6USQDZZSQFD2GRKUC4V5YWPYXJFILKLVEA7IJB2MY4ILWEJ3TC6MG7VQVFHK7PE6VH5KT2QUPWH4KPYOT6EY4DDWEBY\"},\"device\":{\"supportedInterfaces\":{}}}},\"version\":\"1.0\"}", rewind: nil) }
  let(:valid_request) { double(:request, env: valid_env, body: valid_body) }

  let(:invalid_env) { { "HTTP_SIGNATURECERTCHAINURL" => 'http://bad.example', "HTTP_SIGNATURE" => 'invalid' } }
  let(:invalid_body) { double(:body, read: '"{ "invalid": true }"', rewind: nil) }
  let(:invalid_request) { double(:request, env: invalid_env, body: invalid_body) }

  describe '#valid!' do
    context 'with a valid, timely, request' do
      it 'returns true' do
        expect(subject.valid!(valid_request)).to eq(true)
      end
    end

    context 'with an invalid request' do
      it 'raises a AlexaVerifier::InvalidCertificateURIError' do
        expect {
          subject.valid!(invalid_request)
        }.to raise_error(AlexaVerifier::InvalidCertificateURIError, "Invalid certificate URI : URI scheme must be 'https'. Got: 'http'.")
      end

      it 'removes a certificate from our store if there is an issue verifying a request' do
        flawed_request = valid_request
        flawed_request.env['HTTP_SIGNATURE'] = 'invalid'

        expect{
          subject.valid!(flawed_request)
        }.to raise_error(AlexaVerifier::InvalidRequestError, 'Signature does not match certificate provided')

        expect(AlexaVerifier::CertificateStore.store[valid_env["HTTP_SIGNATURECERTCHAINURL"]]).to be_nil
      end
    end
  end

  describe '#valid?' do
    context 'with a valid request' do
      it 'returns true' do
        expect(subject.valid?(valid_request)).to eq(true)
      end
    end

    context 'with an invalid request' do
      it 'returns false' do
        expect(subject.valid?(invalid_request)).to eq(false)
      end
    end
  end

  describe '#configure' do
    after :each do
      subject.configuration = AlexaVerifier::Configuration.new
    end

    context 'when passing a block' do
      context 'that disables all settings' do
        before :each do
          subject.configure do |config|
            config.enabled = false
          end
        end

        it 'does not run any validation' do
          expect(subject.valid!(invalid_request)).to eq(true)
        end
      end

      context 'that disables certificate uri checking' do
        before :each do
          # Set our configuration
          subject.configure do |config|
            config.verify_uri = false
          end

          # Mock our certificate request
          file = File.open('./spec/fixtures/echo-api-cert.pem', 'rb')
          certificate_data = file.read
          file.close
          stub_request(:any, /bad.example/).to_return(body: certificate_data)

          # Set up our modified request
          modified_request = valid_request
          modified_request.env['HTTP_SIGNATURECERTCHAINURL'] = 'http://bad.example'

          @result = subject.valid!(modified_request)
        end

        it 'downloads the certificate from the invalid address' do
          expect(a_request(:get, 'https://bad.example:80')).to have_been_made.times(1)
        end

        it 'adds our \'invalid\' certificate to our certificate store' do
          expect(AlexaVerifier::CertificateStore.store['http://bad.example']).not_to be_nil
        end

        it 'returns true when you call #valid! with an invalid certificate address' do
          expect(@result).to eq(true)
        end
      end

      context 'that disables timeliness checking' do
        before :each do
          # Set our configuration
          subject.configure do |config|
            config.verify_timeliness = false
          end

          # Move us into the 'future' so our request is old
          Timecop.freeze(Time.local(2017,11,21))
        end

        it 'returns true when you call #valid! with an untimely request' do
          expect(subject.valid!(valid_request)).to eq(true)
        end
      end

      context 'that disables certificate checking' do
        before :each do
          # Set our configuration
          subject.configure do |config|
            config.verify_certificate = false
          end

          # Fetch our certificate and load it into our certificate store
          AlexaVerifier::CertificateStore.fetch('https://s3.amazonaws.com/echo.api/echo-api-cert-5.pem')

          # Modify the certificate to make it out of date and remove the SANs
          modified_certificate, _ = AlexaVerifier::CertificateStore.fetch('https://s3.amazonaws.com/echo.api/echo-api-cert-5.pem')
          modified_certificate.not_before = Time.local(1990,01,01)
          modified_certificate.not_after = Time.local(1991,01,01)
          modified_certificate.extensions = []

          AlexaVerifier::CertificateStore.store['https://s3.amazonaws.com/echo.api/echo-api-cert-5.pem'][:certificate] = modified_certificate
        end

        after :each do
          # Reset our certificate store
          AlexaVerifier::CertificateStore.instance_variable_set(:@store, nil)
        end

        it 'returns true when you call #valid! with an invalid certificate in our store' do
          expect(subject.valid!(valid_request)).to eq(true)
        end
      end

      context 'that disables signature checking' do
        before :each do
          # Set our configuration
          subject.configure do |config|
            config.verify_signature = false
          end

          # Set up our modified request
          modified_request = valid_request
          modified_request.env['HTTP_SIGNATURE'] = 'invalid'

          @result = subject.valid!(modified_request)
        end

        it 'returns true when you call #valid! with an invalid signature' do
          expect(@result).to eq(true)
        end
      end
    end
  end
end
