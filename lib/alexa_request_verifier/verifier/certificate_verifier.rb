require 'json'
require 'time'
require 'net/http'
require 'openssl'
require 'base64'

module AlexaRequestVerifier
  module Verifier
    # Given an OpenSSL certificate, validate it according to:
    # https://developer.amazon.com/docs/custom-skills/host-a-custom-skill-as-a-web-service.html#h2_verify_sig_cert
    #
    # @since 0.1
    module CertificateVerifier
      SAN = 'echo-api.amazon.com'.freeze

      class << self
        # Check that a given certificate meet's Amazon's requirements.
        # Raise an error if it does not.
        #
        # @param [OpenSSL::X509::Certificate] certificate certificate to check.
        #
        # @raise [AlexaRequestVerifier::InvalidCertificateError] raised when
        #   the provided certificate does not meet a requirement
        #
        # @return [true] either returns true or raises an error.
        def valid!(certificate)
          # Check that it's in date
          certificate_in_date = Time.now.between?(certificate.not_before, certificate.not_after)
          raise AlexaRequestVerifier::InvalidCertificateError, 'Certificate is not in date.' unless certificate_in_date

          # Check that the required SAN is present
          valid_sans = certificate.extensions.select do |extension|
            valid_oid = (extension.oid == 'subjectAltName')
            valid_value = (extension.value == "DNS:#{SAN}")

            valid_oid && valid_value
          end
          raise AlexaRequestVerifier::InvalidCertificateError, "Certificate does not contain SAN: #{SAN}." if valid_sans.empty?

          # TODO: Check that the certificate is valid up to the root CA

          true
        end

        # Check that a given certificate meet's Amazon's requirements.
        # Returns a boolean.
        #
        # @param [OpenSSL::X509::Certificate] certificate certificate to check.
        #
        # @return [Boolean] returns the result of our checks.
        def valid?(certificate)
          begin
            valid!(certificate)
          rescue AlexaRequestVerifier::InvalidCertificateError => e
            puts e

            return false
          end

          true
        end
      end
    end
  end
end
