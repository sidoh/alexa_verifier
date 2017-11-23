require 'alexa_verifier/certificate_store'
require 'alexa_verifier/configuration'
require 'alexa_verifier/verifier'
require 'alexa_verifier/version'

# Errors
require 'alexa_verifier/base_error'
require 'alexa_verifier/invalid_certificate_error'
require 'alexa_verifier/invalid_certificate_u_r_i_error'
require 'alexa_verifier/invalid_request_error'

# Verify that HTTP requests sent to an Alexa skill are sent from Amazon
# @since 0.1.0
module AlexaVerifier
  REQUEST_THRESHOLD = 150 # Requests must be received within X seconds

  class << self
    attr_reader :verifier

    # Returns our configuration object.
    #
    # @return [AlexaVerifier::Configuration] our configuration object
    def configuration
      verifier.configuration
    end

    # Sets a new configuration object.
    #
    # @param [AlexaVerifier::Configuration] configuration new configuration object
    # @return [AlexaVerifier::Configuration] configuration object
    def configuration=(configuration)
      verifier.configuration = configuration
    end

    # Delegate all methods to the verifier object, essentially making the
    # module object behave like a {Verifier}.
    def method_missing(m, *args, &block)
      if verifier.respond_to?(m)
        verifier.send(m, *args, &block)
      else
        super
      end
    end

    # Delegating +respond_to+ to the {Verifier}.
    def respond_to_missing?(m, include_private = false)
      verifier.respond_to?(m) || super
    end

    private

    # Initialize a new instance of our Verifier to hold global configurations.
    def initialize_verifier
      @verifier = AlexaVerifier::Verifier.new
    end
  end

  initialize_verifier
end
