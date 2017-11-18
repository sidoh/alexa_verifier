require 'spec_helper'

RSpec.describe AlexaRequestVerifier, vcr: true do
  it 'has a version number' do
    expect(AlexaRequestVerifier::VERSION).not_to be nil
  end

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
      it 'raises a AlexaRequestVerifier::InvalidCertificateURIError' do
        expect {
          subject.valid!(invalid_request)
        }.to raise_error(AlexaRequestVerifier::InvalidCertificateURIError, "Invalid certificate URI : URI scheme must be 'https'. Got: 'http'.")
      end

      it 'removes a certificate from our store if there is an issue verifying a request' do
        flawed_request = valid_request
        flawed_request.env['HTTP_SIGNATURE'] = 'invalid'

        expect{
          subject.valid!(flawed_request)
        }.to raise_error(AlexaRequestVerifier::InvalidRequestError, 'Signature does not match certificate provided')

        expect(AlexaRequestVerifier::CertificateStore.store[valid_env["HTTP_SIGNATURECERTCHAINURL"]]).to be_nil
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
end
