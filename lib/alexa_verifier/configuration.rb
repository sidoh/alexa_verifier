module AlexaVerifier
  # Stores our configuration information
  # @since 0.2.0
  class Configuration
    attr_accessor :enabled, :verify_uri, :verify_timeliness, :verify_certificate, :verify_signature

    # Create a new instance of our configuration object that has all of our settings enabled
    def initialize
      @enabled            = true
      @verify_uri         = true
      @verify_timeliness  = true
      @verify_certificate = true
      @verify_signature   = true
    end

    # Is AlexaVerifier enabled?
    #
    # This setting overrides all other settings
    #
    # @return [Boolean]
    def enabled?
      @enabled
    end

    # Should we verify the certificate URI?
    #
    # @return [Boolean]
    def verify_uri?
      @enabled ? @verify_uri : @enabled
    end

    # Should we verify the request's timeliness?
    #
    # @return [Boolean]
    def verify_timeliness?
      @enabled ? @verify_timeliness : @enabled
    end

    # Should we verify that the certificate is 'valid'?
    #
    # @return [Boolean]
    def verify_certificate?
      @enabled ? @verify_certificate : @enabled
    end

    # Should we verify that the request was signed with our certificate?
    #
    # @return [Boolean]
    def verify_signature?
      @enabled ? @verify_signature : @enabled
    end
  end
end
