require 'json'
require 'time'
require 'net/http'
require 'openssl'
require 'base64'

module AlexaVerifier
  class Verifier
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
        # @param [Array<OpenSSL::X509::Certificate>] chain chain of certificates to a root trusted CA.
        #
        # @raise [AlexaVerifier::InvalidCertificateError] raised when
        #   the provided certificate does not meet a requirement
        #
        # @return [true] either returns true or raises an error.
        def valid!(certificate, chain)
          check_that_certificate_is_in_date(certificate)

          check_that_certificate_has_the_expected_extensions(certificate)

          check_that_we_can_create_a_chain_of_trust_to_a_root_ca(certificate, chain)

          true
        end

        # Check that a given certificate meet's Amazon's requirements.
        # Returns a boolean.
        #
        # @param [OpenSSL::X509::Certificate] certificate certificate to check.
        # @param [Array<OpenSSL::X509::Certificate>] chain chain of certificates to a root CA.
        #
        # @return [Boolean] returns the result of our checks.
        def valid?(certificate, chain)
          begin
            valid!(certificate, chain)
          rescue AlexaVerifier::InvalidCertificateError => e
            puts e

            return false
          end

          true
        end

        private

        # Given a certificate file, check that it is in date.
        #
        # @param [OpenSSL::X509::Certificate] certificate the certificate we should check
        #
        # @raise [AlexaVerifier::InvalidCertificateError] raised if the certificate is not in date
        def check_that_certificate_is_in_date(certificate)
          certificate_in_date = Time.now.between?(certificate.not_before, certificate.not_after)
          raise AlexaVerifier::InvalidCertificateError, 'Certificate is not in date.' unless certificate_in_date
        end

        # Given a certificate file, check that it contains our expected extensions
        #
        # @param [OpenSSL::X509::Certificate] certificate the certificate we should check
        #
        # @raise [AlexaVerifier::InvalidCertificateError] raised if the extensions are not present
        def check_that_certificate_has_the_expected_extensions(certificate)
          valid_sans = certificate.extensions.select do |extension|
            valid_oid = (extension.oid == 'subjectAltName')
            valid_value = (extension.value == "DNS:#{SAN}")

            valid_oid && valid_value
          end
          raise AlexaVerifier::InvalidCertificateError, "Certificate does not contain SAN: #{SAN}." if valid_sans.empty?
        end

        # Check that the certificate, along with any chain from our downloaded certificate file, makes a chain of trust to a trusted root CA
        #
        # @param [OpenSSL::X509::Certificate] certificate certificate we should check
        # @param [Array<OpenSSL::X509::Certificate>] chain chain of certificates to a root trusted CA
        #
        # @raise [AlexaVerifier::InvalidCertificateError] raised if a chain of trust could not be established
        def check_that_we_can_create_a_chain_of_trust_to_a_root_ca(certificate, chain)
          openssl_x509_store = OpenSSL::X509::Store.new
          openssl_x509_store.set_default_paths

          valid_certificate_chain = openssl_x509_store.verify(certificate, chain)
          raise AlexaVerifier::InvalidCertificateError, "Unable to create a 'chain of trust' from the provided certificate to a trusted root CA." unless valid_certificate_chain
        end
      end
    end
  end
end
