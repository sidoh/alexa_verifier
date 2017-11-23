require_relative 'verifier/certificate_verifier'
require_relative 'verifier/certificate_u_r_i_verifier'

module AlexaVerifier
  # A namespace for all of our verifiers to live under
  # @since 0.1
  class Verifier
    attr_accessor :configuration

    # Create a new AlexaVerifier::Verifier object
    #
    # @yield the configuration block
    # @yieldparam config [AlexaVerifier::Configuration] the configuration object
    def initialize
      @configuration = AlexaVerifier::Configuration.new

      yield @configuration if block_given?
    end

    # Validate a request object from Rack.
    # Raise an error if it is not valid.
    #
    # @param [Rack::Request::Env] request a Rack HTTP Request
    #
    # @raise [AlexaVerifier::InvalidCertificateURIError]
    #   there was a problem validating the certificate URI from your request
    #
    # @return [nil] will always return nil
    def valid!(request)
      signature_certificate_url = request.env['HTTP_SIGNATURECERTCHAINURL']

      AlexaVerifier::Verifier::CertificateURIVerifier.valid!(signature_certificate_url) if @configuration.verify_uri?

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
      rescue AlexaVerifier::BaseError => e
        puts e

        return false
      end

      true
    end

    # Used to configure AlexaVerifier.
    #
    # @example
    #    AlexaVerifier.configure do |c|
    #      c.some_config_option = true
    #    end
    #
    # @yield the configuration block
    # @yieldparam config [AlexaVerifier::Configuration] the configuration object
    def configure
      yield @configuration
    end

    private

    # Prevent replays of requests by checking that they are timely.
    #
    # @param [String] raw_body the raw body of our https request
    # @raise [AlexaVerifier::InvalidRequestError] raised when the timestamp is not timely, or is not set
    def check_that_request_is_timely(raw_body)
      request_json = JSON.parse(raw_body)

      raise AlexaVerifier::InvalidRequestError, 'Timestamp field not present in request' if request_json.fetch('request', {}).fetch('timestamp', nil).nil?

      request_is_timely = (Time.parse(request_json['request']['timestamp'].to_s) >= (Time.now - REQUEST_THRESHOLD))
      raise AlexaVerifier::InvalidRequestError, "Request is from more than #{REQUEST_THRESHOLD} seconds ago" unless request_is_timely
    end

    # Check that our request is valid.
    #
    # @param [String] signature_certificate_url the url for our signing certificate
    # @param [Rack::Request::Env] request the request object
    # @param [String] raw_body the raw body of our https request
    def check_that_request_is_valid(signature_certificate_url, request, raw_body)
      certificate, chain = AlexaVerifier::CertificateStore.fetch(signature_certificate_url) if @configuration.verify_certificate? || @configuration.verify_signature?

      begin
        AlexaVerifier::Verifier::CertificateVerifier.valid!(certificate, chain) if @configuration.verify_certificate?

        check_that_request_was_signed(certificate.public_key, request, raw_body) if @configuration.verify_signature?
      rescue AlexaVerifier::InvalidCertificateError, AlexaVerifier::InvalidRequestError => error
        # We don't want to cache a certificate that fails our checks as it could lock us out of valid requests for the cache length
        AlexaVerifier::CertificateStore.delete(signature_certificate_url)

        raise error
      end
    end

    # Check that our request was signed by a given public key.
    #
    # @param [OpenSSL::PKey::PKey] certificate_public_key the public key we are checking
    # @param [Rack::Request::Env] request the request object we are checking
    # @param [String] raw_body the raw body of our https request
    # @raise [AlexaVerifier::InvalidRequestError] raised if our signature does not match the certificate provided
    def check_that_request_was_signed(certificate_public_key, request, raw_body)
      signed_by_certificate = certificate_public_key.verify(
        OpenSSL::Digest::SHA1.new,
        Base64.decode64(request.env['HTTP_SIGNATURE']),
        raw_body
      )

      raise AlexaVerifier::InvalidRequestError, 'Signature does not match certificate provided' unless signed_by_certificate
    end
  end
end
