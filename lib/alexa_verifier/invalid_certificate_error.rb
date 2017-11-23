module AlexaVerifier
  # An error that is raised when the certificate referenced from a request is
  # invalid.
  #
  # @since 0.1
  class InvalidCertificateError < AlexaVerifier::BaseError
  end
end
