require 'net/http'
require 'openssl'
require 'base64'

class AlexaVerifier
  VERSION = '0.1.0'

  class VerificationError < StandardError; end

  VALID_CERT_HOSTNAME = 's3.amazonaws.com'
  VALID_CERT_PATH_START = '/echo.api/'
  VALID_CERT_PORT = 443

  def initialize
    @cert_cache = {}
  end

  def verify!(cert_url, signature, request)
    x509_cert = cert(cert_url)
    public_key = x509_cert.public_key

    if public_key.verify(hash_type, Base64.decode64(signature), request)
      true
    else
      raise VerificationError.new, 'Signature does not match!'
    end
  end

  private

    def hash_type
      OpenSSL::Digest::SHA1.new
    end

    def cert(cert_url)
      if @cert_cache[cert_url]
        @cert_cache[cert_url]
      else
        cert_uri = URI.parse(cert_url)
        validate_cert_uri!(cert_uri)
        @cert_cache[cert_url] = OpenSSL::X509::Certificate.new(download_cert(cert_uri))
      end
    end

    def download_cert(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.start

      response = http.request(Net::HTTP::Get.new(uri.request_uri))

      http.finish

      if response.code == '200'
        response.body
      else
        raise RuntimeError.new, "Failed to download certificate. Response code: #{response.code}, error: #{response.body}"
      end
    end

    def validate_cert_uri!(cert_uri)
      unless cert_uri.scheme == 'https'
        raise VerificationError, "Certificate URI MUST be https: #{cert_uri}"
      end

      unless cert_uri.port == VALID_CERT_PORT
        raise VerificationError, "Certificate URI port MUST be #{VALID_CERT_PORT}, was: #{cert_uri.port}"
      end

      unless cert_uri.host == VALID_CERT_HOSTNAME
        raise VerificationError, "Certificate URI hostname must be #{VALID_CERT_HOSTNAME}: #{cert_uri}"
      end

      unless cert_uri.request_uri.start_with?(VALID_CERT_PATH_START)
        raise VerificationError, "Certificate URI path must start with #{VALID_CERT_PATH_START}: #{cert_uri}"
      end
    end
end
