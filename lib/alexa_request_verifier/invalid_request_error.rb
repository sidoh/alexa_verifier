module AlexaRequestVerifier
  # An error that is raised when the certificate referenced from a request is
  # invalid.
  #
  # @since 0.1
  class InvalidRequestError < AlexaRequestVerifier::BaseError
  end
end
