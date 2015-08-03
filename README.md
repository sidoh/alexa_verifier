# alexa_verifier
Rubygem to verify requests sent to an Alexa skill are sent from Amazon

## Installing

alexa_verifier is available on [Rubygems](https://rubygems.org). You can install it with:

```
$ gem install alexa_verifier
```

You can also add it to your Gemfile:

```
gem 'alexa_verifier'
```

## What is it?

Amazon requires publicly registered skills validate requests sent to it. This includes doing the following:

1. Verifying that the timestamp in the request is from not too long ago (Amazon recommends a max of 150 seconds).
2. Verifying that the signature sent is valid against the request.

This gem takes care of both of these. You can read more about the technical specifications [here](https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/developing-an-alexa-skill-as-a-web-service#Verifying that the Request was Sent by Alexa).

## Example usage

To create an instance of `AlexaVerifier`, you can simply call `AlexaVerifier.new`. By default, it will verify that timestamps are within 150 seconds and that signatures match. To configure this behavior, you can use `AlexaVerifier.build`:

```ruby
verifier = AlexaVerifier.build do |c|
  c.verify_signatures = true
  c.verify_timestamps = true
  c.timestamp_tolerance = 60 # seconds
end
```

To validate a request, you need three things:

1. The request itself (raw JSON string)
2. The HTTP header `SignatureCertChainUrl`
3. The HTTP header `Signature`

When you have each of these, you can pass them to `AlexaVerifier#verify!`. If verification passes, it returns `true`. If it fails, an `AlexaVerifier::VerificationError` will be thrown. Here's an example:

```ruby
verifier.verify!(
    request.headers['SignatureCertChainUrl'], 
    request.headers['Signature'], 
    request.body.read
)
```

## Credits

This code was adapted from signature verification code found in the [AWS SNS module](https://github.com/aws/aws-sdk-ruby/blob/master/aws-sdk-resources/lib/aws-sdk-resources/services/sns/message_verifier.rb).
