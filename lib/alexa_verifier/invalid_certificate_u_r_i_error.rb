module AlexaVerifier
  # An error that is raised when the certificate URI from a request is invalid.
  # @since 0.1
  class InvalidCertificateURIError < AlexaVerifier::BaseError
    # Create a new instance of our InvalidCertificateURIError
    #
    # @param [String] message the main message we want to include
    # @param [String] value an optional value used when creating a message.
    #
    # @example Error without a value
    #   AlexaVerifier::InvalidCertificateURIError.new(
    #     'No URI Passed'
    #   ) #=> #<AlexaVerifier::InvalidCertificateURIError
    #             @message="Invalid certificate URI : No URI Passed.">
    #
    # @example Error with a valuex
    #   AlexaVerifier::InvalidCertificateURIError.new(
    #     "Expected 'a'",
    #     'b'
    #   ) #=> #<AlexaVerifier::InvalidCertificateURIError
    #             @message="Invalid certificate URI : Expected 'a'. Got: 'b'.">
    #
    # @return [AlexaVerifier::InvalidCertificateURIError] a new instance
    def initialize(message, value = nil)
      error_message = "Invalid certificate URI : #{message}."
      error_message = "#{error_message} Got: '#{value}'." if value

      super(error_message)
    end
  end
end
