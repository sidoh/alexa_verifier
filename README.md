# Alexa Request Verifier

[AlexaRequestVerifier][alexa_request_verifier] is a gem created to verify that requests received within a Sinatra application originate from Amazon's Alexa API.

[![Build Status][shield-travis]][info-travis] [![Code Coverage][shield-coveralls]][info-coveralls] [![License][shield-license]][info-license]

## Requirements
[AlexaRequestVerifier][alexa_request_verifier] requires the following:
* [Ruby][ruby] - version 2.0 or greater


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'alexa_request_verifier'
```


## Usage
This gem's main function is taking an [Sinatra][sinatra] request and verifying that it was sent by Amazon.

```ruby
# within server.rb (or equivalent)

post '/' do
  AlexaRequestVerifier.valid!(request)
end
```

### Methods
[AlexaRequestVerifier][alexa_request_verifier] has two main entry points, detailsed below:

Method | Parameter type | Returns
---|---|---
`AlexaRequestVerifier.valid!(request)` | `Sinatra::Request` | `true` on successful verification. Raises an error if unsuccessful.
`AlexaRequestVerifier.valid?(request)` | `Sinatra::Request` | `true` on successful verificatipn. `false` if unsuccessful.


### Handling errors
AlexaRequestVerifier#valid! will raise one of the following *expected* errors if verification cannot be performed.

> Please note that all errors come with (hopefully) helpful accompanying messages.

Error | Description
---|---
`AlexaRequestVerifier::InvalidCertificateURIError` | Raised when the certificate URI does not pass validation.
`AlexaRequestVerifier::InvalidCertificateError` | Raised when the certificate itself does not pass validation e.g. out of date, does not contain the requires SAN extension, etc.
`AlexaRequestVerifier::InvalidRequestError` | Raised when the request cannot be verified (not timely, not signed with the certificate, etc.)


## Getting Started with Development
To clone the repository and set up the dependencies, run the following:
```bash
git clone https://github.com/mattrayner/alexa_request_verifier.git
cd alexa_request_verifier
bundle install
```

### Running the tests
We use [RSpec][rspec] as our testing framework and tests can be run using:
```bash
bundle exec rake
```


## Contributing
If you wish to submit a bug fix or feature, you can create a pull request and it will be merged pending a code review.

1. Fork the repository
1. Create your feature branch (`git checkout -b my-new-feature`)
1. Commit your changes (`git commit -am 'Add some feature'`)
1. Push to the branch (`git push origin my-new-feature`)
1. Ensure your changes are tested using [Rspec][rspec]
1. Create a new Pull Request


## License
[AlexaRequestVerifier][alexa_request_verifier] is licensed under the [MIT][info-license].

## Code of Conduct

Everyone interacting in the AlexaRequestVerifier project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct][code_of_conduct].

[alexa_request_verifier]: https://github.com/mattrayner/alexa_request_verifier
[ruby]:                   http://ruby-lang.org
[rspec]:                  http://rspec.info
[code_of_conduct]:        https://github.com/mattrayner/alexa_request_verifier/blob/master/CODE_OF_CONDUCT.md

[info-travis]:   https://travis-ci.org/mattrayner/alexa_request_verifier
[shield-travis]: https://img.shields.io/travis/mattrayner/alexa_request_verifier.svg

[info-coveralls]:   https://coveralls.io/github/mattrayner/alexa_request_verifier
[shield-coveralls]: https://img.shields.io/coveralls/github/mattrayner/alexa_request_verifier.svg

[info-license]:   https://github.com/mattrayner/alexa_request_verifier/blob/master/LICENSE
[shield-license]: https://img.shields.io/badge/license-MIT-blue.svg