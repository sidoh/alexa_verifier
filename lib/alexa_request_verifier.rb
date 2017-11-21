require 'alexa_request_verifier/certificate_store'
require 'alexa_request_verifier/verifier'
require 'alexa_request_verifier/version'

# Errors
require 'alexa_request_verifier/base_error'
require 'alexa_request_verifier/invalid_certificate_error'
require 'alexa_request_verifier/invalid_certificate_u_r_i_error'
require 'alexa_request_verifier/invalid_request_error'

# Verify that HTTP requests sent to an Alexa skill are sent from Amazon
# @since 0.1.0
module AlexaRequestVerifier
  REQUEST_THRESHOLD = 150 # Requests must be received within X seconds

  class << self
    # Validate a request object from Sinatra.
    # Raise an error if it is not valid.
    #
    # @param [Sinatra::Request] request a Sinatra HTTP Request
    #
    # @raise [AlexaRequestVerifier::InvalidCertificateURIError]
    #   there was a problem validating the certificate URI from your request
    #
    # @return [nil] will always return nil
    def valid!(request)
      signature_certificate_url = request.env['HTTP_SIGNATURECERTCHAINURL']

      AlexaRequestVerifier::Verifier::CertificateURIVerifier.valid!(signature_certificate_url)

      raw_body = request.body.read
      request.body.rewind

      check_that_request_is_timely(raw_body)

      check_that_request_is_valid(signature_certificate_url, request, raw_body)

      true
    end

    # Validate a request object from Sinatra.
    # Return a boolean.
    #
    # @param [Sinatra::Request] request a Sinatra HTTP Request
    # @return [Boolean] is the request valid?
    def valid?(request)
      begin
        valid!(request)
      rescue AlexaRequestVerifier::BaseError => e
        puts e

        return false
      end

      true
    end

    private

    # Prevent replays of requests by checking that they are timely.
    #
    # @param [String] raw_body the raw body of our https request
    # @raise [AlexaRequestVerifier::InvalidRequestError] raised when the timestamp is not timely, or is not set
    def check_that_request_is_timely(raw_body)
      request_json = JSON.parse(raw_body)

      raise AlexaRequestVerifier::InvalidRequestError, 'Timestamp field not present in request' if request_json.fetch('request', {}).fetch('timestamp', nil).nil?

      raise AlexaRequestVerifier::InvalidRequestError, 'Request is from more than 150 seconds ago' unless Time.parse(request_json['request']['timestamp'].to_s) >= (Time.now - REQUEST_THRESHOLD)
    end

    # Check that our request is valid.
    #
    # @param [String] signature_certificate_url the url for our signing certificate
    # @param [Sinatra::Request] request the request object
    # @param [String] raw_body the raw body of our https request
    def check_that_request_is_valid(signature_certificate_url, request, raw_body)
      certificate, chain = AlexaRequestVerifier::CertificateStore.fetch(signature_certificate_url)

      begin
        AlexaRequestVerifier::Verifier::CertificateVerifier.valid!(certificate, chain)

        check_that_request_was_signed(certificate.public_key, request, raw_body)
      rescue AlexaRequestVerifier::InvalidCertificateError, AlexaRequestVerifier::InvalidRequestError => error
        # We don't want to cache a certificate that fails our checks as it could lock us out of valid requests for the cache length
        AlexaRequestVerifier::CertificateStore.delete(signature_certificate_url)

        raise error
      end
    end

    # Check that our request was signed by a given public key.
    #
    # @param [OpenSSL::PKey::PKey] certificate_public_key the public key we are checking
    # @param [Sinatra::Request] request the request object we are checking
    # @param [String] raw_body the raw body of our https request
    # @raise [AlexaRequestVerifier::InvalidRequestError] raised if our signature does not match the certificate provided
    def check_that_request_was_signed(certificate_public_key, request, raw_body)
      signed_by_certificate = certificate_public_key.verify(
        OpenSSL::Digest::SHA1.new,
        Base64.decode64(request.env['HTTP_SIGNATURE']),
        raw_body
      )

      raise AlexaRequestVerifier::InvalidRequestError, 'Signature does not match certificate provided' unless signed_by_certificate
    end
  end
end
