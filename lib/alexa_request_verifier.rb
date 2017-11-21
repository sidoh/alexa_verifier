require 'alexa_request_verifier/certificate_store'
require 'alexa_request_verifier/configuration'
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
    attr_reader :configuration

    # Validate a request object from Rack.
    # Raise an error if it is not valid.
    #
    # @param [Rack::Request::Env] request a Rack HTTP Request
    #
    # @raise [AlexaRequestVerifier::InvalidCertificateURIError]
    #   there was a problem validating the certificate URI from your request
    #
    # @return [nil] will always return nil
    def valid!(request)
      signature_certificate_url = request.env['HTTP_SIGNATURECERTCHAINURL']

      AlexaRequestVerifier::Verifier::CertificateURIVerifier.valid!(signature_certificate_url) if @configuration.verify_uri?

      raw_body = request.body.read
      request.body && request.body.rewind # call the rewind method if it exists (handles Sinatra specifically)

      check_that_request_is_timely(raw_body) if @configuration.verify_timeliness?

      check_that_request_is_valid(signature_certificate_url, request, raw_body)

      true
    end

    # Validate a request object from Rack.
    # Return a boolean.
    #
    # @param [Rack::Request::Env] request a Rack HTTP Request
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

    # Used to configure AlexaRequestVerifier.
    #
    # @example
    #    AlexaRequestVerifier.configure do |c|
    #      c.some_config_option = true
    #    end
    #
    # @yield the configuration block
    # @yieldparam config [AlexaRequestVerifier::Configuration] the configuration object
    def configure
      yield @configuration
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
    # @param [Rack::Request::Env] request the request object
    # @param [String] raw_body the raw body of our https request
    def check_that_request_is_valid(signature_certificate_url, request, raw_body)
      certificate, chain = AlexaRequestVerifier::CertificateStore.fetch(signature_certificate_url) if @configuration.verify_certificate? || @configuration.verify_signature?

      begin
        AlexaRequestVerifier::Verifier::CertificateVerifier.valid!(certificate, chain) if @configuration.verify_certificate?

        check_that_request_was_signed(certificate.public_key, request, raw_body) if @configuration.verify_signature?
      rescue AlexaRequestVerifier::InvalidCertificateError, AlexaRequestVerifier::InvalidRequestError => error
        # We don't want to cache a certificate that fails our checks as it could lock us out of valid requests for the cache length
        AlexaRequestVerifier::CertificateStore.delete(signature_certificate_url)

        raise error
      end
    end

    # Check that our request was signed by a given public key.
    #
    # @param [OpenSSL::PKey::PKey] certificate_public_key the public key we are checking
    # @param [Rack::Request::Env] request the request object we are checking
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

    def initialize_configuration
      @configuration = AlexaRequestVerifier::Configuration.new
    end
  end

  initialize_configuration
end
