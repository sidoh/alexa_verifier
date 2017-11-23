module AlexaVerifier
  class Verifier
    # Given an Alexa certificate URI, validate it according to:
    # https://developer.amazon.com/docs/custom-skills/host-a-custom-skill-as-a-web-service.html#h2_verify_sig_cert
    #
    # @since 0.1
    module CertificateURIVerifier
      VALIDATIONS = {
        scheme: 'https',
        port:   443,
        host:   's3.amazonaws.com'
      }.freeze

      PATH_REGEX = %r{\A\/echo.api\/}

      class << self
        # Check that a given certificate URI meets Amazon's requirements.
        # Raise an error if it does not.
        #
        # @param [String] uri The URI value from HTTP_SIGNATURECERTCHAINURL
        #
        # @raise [AlexaVerifier::InvalidCertificateURIError] An error
        #   raised when the URI does not meet a requirement
        #
        # @return [true] This method will either raise an error or return true
        def valid!(uri)
          begin
            uri = URI.parse(uri)
          rescue URI::InvalidURIError => e
            puts e

            raise AlexaVerifier::InvalidCertificateURIError,
                  "#{uri} : #{e.message}"
          end

          test_validations(uri)

          test_path(uri)

          true
        end

        # Check that a given certificate URI meets Amazon's requirements
        # Return true if it does, or false if it does not.
        #
        # @param [String] uri The URI value from HTTP_SIGNATURECERTCHAINURL
        #
        # @return [Boolean] Returns true if the uri is valid and false if not
        def valid?(uri)
          begin
            valid!(uri)
          rescue AlexaVerifier::InvalidCertificateURIError => e
            puts e

            return false
          end

          true
        end

        private

        # Test that a given URI meets all of our 'simple' validation rules.
        #
        # @param [URI] uri the URI object to test
        def test_validations(uri)
          VALIDATIONS.each do |method, value|
            next if uri.send(method) == value

            raise AlexaVerifier::InvalidCertificateURIError.new(
              "URI #{method} must be '#{value}'",
              uri.send(method)
            )
          end
        end

        # Test that a given URI matches our 'path' regex.
        #
        # @param [URI] uri the URI object to test
        def test_path(uri)
          path = File.absolute_path(uri.path)

          return if path.match(PATH_REGEX) # rubocop:disable Performance/RegexpMatch # Disabled for backwards compatibility below 2.4

          raise AlexaVerifier::InvalidCertificateURIError.new(
            "URI path must start with '/echo.api/'",
            uri.path
          )
        end
      end
    end
  end
end
