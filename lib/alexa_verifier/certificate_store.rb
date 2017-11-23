module AlexaVerifier
  # A module used to download, cache and serve certificates from our requests.
  # @since 0.1
  module CertificateStore
    CERTIFICATE_CACHE_TIME = 1800 # 30 minutes
    CERTIFICATE_SEPARATOR = '-----BEGIN CERTIFICATE-----'.freeze

    class << self
      # Given a certificate uri, either download the certificate and chain, or
      # load them from our certificate store.
      #
      # @param [String] uri the uri of our certificate
      # @return [OpenSSL::X509::Certificate, Array<OpenSSL::X509::Certificate>] our certificate file and chain
      def fetch(uri)
        store

        if cache_valid?(@store[uri])
          certificate = @store[uri][:certificate]
          chain = @store[uri][:chain]
        else
          chain = generate_certificate_chain_from_data(download_certificate(uri))
          certificate = chain.delete_at(0)

          @store[uri] = { timestamp: Time.now, certificate: certificate, chain: chain }
        end

        [certificate, chain]
      end

      # Given a certificate uri, remove the certificate from our store.
      #
      # @param [String] uri the uri of our certificate
      # @return [nil|Hash] returns nil if the certificate was not in the store,
      #   or a Hash representing the deleted certificate
      def delete(uri)
        store

        @store.delete(uri)
      end

      # Returns a copy of our certificate store
      #
      # @return [Hash] returns our certificate store
      def store
        @store ||= {}
      end

      private

      # Given a certificate entry from our store, tell us if the cache is still valid
      #
      # @param [Hash] certificate_entry the entry we are checking
      # @return [Boolean] is the certificate cache valid?
      def cache_valid?(certificate_entry)
        return false if certificate_entry.nil?

        (Time.now <= (certificate_entry[:timestamp] + CERTIFICATE_CACHE_TIME))
      end

      # Given a certificate uri, download it and return the certificate data
      #
      # @param [String] uri the uri of our certificates
      # @return [String] certificate data
      def download_certificate(uri)
        certificate_uri = URI.parse(uri)

        certificate_data = nil

        Net::HTTP.start(certificate_uri.host, certificate_uri.port, use_ssl: true) do |http|
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER

          response = http.request(Net::HTTP::Get.new(certificate_uri))

          raise AlexaVerifier::InvalidCertificateError, "Unable to download certificate from #{certificate_uri} - Got #{response.code} status code" unless response.is_a? Net::HTTPOK

          certificate_data = response.body
        end

        certificate_data
      end

      # Given a string of certificate data, which may contain one or more certificates,
      # convert it into an array of certificate object representing the full chain.
      #
      # @param [String] certificate_data the certificate data we should build our chain from
      # @return [Array<OpenSSL::X509::Certificate>] an array of certificate objects representing our chain
      def generate_certificate_chain_from_data(certificate_data)
        split_data = certificate_data.split(CERTIFICATE_SEPARATOR)

        # Remove any empty string artifacts
        split_data.reject! { |data| data.strip.empty? }

        # Convert our array of split out certificate data strings, into an array of certificate objects
        split_data.map { |data| OpenSSL::X509::Certificate.new(CERTIFICATE_SEPARATOR + data) }
      end
    end
  end
end
