# Alexa Verifier

[AlexaVerifier][alexa_verifier] is a gem created to verify that requests received within a [Rack][rack]-based application originate from Amazon's Alexa API.

This gem is framework agnostic and should work with any Rack based application including both [Rails][rails] and [Sinatra][sinatra].

[![Gem Version][shield-gem]][info-gem] [![Build Status][shield-travis]][info-travis] [![Code Coverage][shield-coveralls]][info-coveralls] [![License][shield-license]][info-license]

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [Methods](#methods)
  - [Disabling checks](#disabling-checks)
    - [Examples](#examples)
      - [Globally](#globally)
      - [Instance level](#instance-level)
        - [With a block](#with-a-block)
        - [Calling `#configure`](#calling-configure)
  - [Handling errors](#handling-errors)
- [Getting Started with Development](#getting-started-with-development)
  - [Running the tests](#running-the-tests)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Requirements
[AlexaVerifier][alexa_verifier] requires the following:
* [Ruby][ruby] - version 2.0 or greater


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'alexa_verifier'
```


## Usage
This gem's main function is taking an [Rack][rack] request and verifying that it was sent by Amazon.

### Sinatra
```ruby
# within server.rb (or equivalent)

post '/' do
  AlexaVerifier.valid!(request)
end
```


### Rails
```ruby
# config/routes.rb

post '/', to: 'alexa#index'
```

```ruby
# app/controllers/alexa_controller.rb

class AlexaController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :index

  def index
    AlexaVerifier.valid!(request)
  end
end
```

### Methods
[AlexaVerifier][alexa_verifier] has two main entry points, detailsed below:

Method | Parameter type | Returns
---|---|---
`AlexaVerifier.valid!(request)` | Rack-based request object | `true` on successful verification. Raises an error if unsuccessful.
`AlexaVerifier.valid?(request)` | Rack-based request object | `true` on successful verificatipn. `false` if unsuccessful.

You are also able to configure [AlexaVerifier][alexa_verifier] to disable some checks. This is detailed in the section below.


### Disabling checks
If you'd like to disable one (or more) of the checks performed by [AlexaVerifier][alexa_verifier], you can do so by passing a #configure block. Each of the configuration attributes are Boolean values and are detailed below.

It is possible to disable checks either globally, or for a specific instance. This is useful if you want to run multiple instances of the verifier within your application.

Option | Default | Description
---|---|---
`enabled` | `true` | Enables or disables AlexaVerifier checks. This setting overrides all others i.e. setting `config.enabled = false` disables all checks even if you set others to true.
`verify_uri` | `true` | Enables or disables checks on the certificate URI. Set to `false` to allow serving of certificates from non-amazon approved domains.
`verify_timeliness` | `true` | Enables or disables timeliness checks. Set to `false` to allow requests generated in the past to be executed. Good for serving test requests.
`verify_certificate` | `true` | Enables or disabled checks on whether the certificate is in date, or contains the SAN address we expect.
`verify_signature` | `true` | Enables or disables checks to see if a request was actually signed by a certificate.

#### Examples
The below is an example of a 'complete' configure block, setting attributes both globally and for an individual instance.

##### Globally
```ruby
AlexaVerifier.configure do |config|
  config.enabled            = false # Disables all checks, even though we enable them individually below
  config.verify_uri         = true
  config.verify_timeliness  = true
  config.verify_certificate = true
  config.verify_signature   = true
end
AlexaVerifier.valid!(request)
```

##### Instance level
###### With a block
```ruby
verifier = AlexaVerifier::Verifier.new do |config|
  config.enabled            = false
  config.verify_uri         = true
  config.verify_timeliness  = true
  config.verify_certificate = true
  config.verify_signature   = true
end
verifier.valid!(request)
```

###### Calling `#configure`
```ruby
verifier = AlexaVerifier::Verifier.new
verifier.configure do |config|
  config.enabled            = false
  config.verify_uri         = true
  config.verify_timeliness  = true
  config.verify_certificate = true
  config.verify_signature   = true
end
verifier.valid!(request)
```


### Handling errors
AlexaVerifier#valid! will raise one of the following *expected* errors if verification cannot be performed.

> Please note that all errors come with (hopefully) helpful accompanying messages.

Error | Description
---|---
`AlexaVerifier::InvalidCertificateURIError` | Raised when the certificate URI does not pass validation.
`AlexaVerifier::InvalidCertificateError` | Raised when the certificate itself does not pass validation e.g. out of date, does not contain the requires SAN extension, etc.
`AlexaVerifier::InvalidRequestError` | Raised when the request cannot be verified (not timely, not signed with the certificate, etc.)


## Getting Started with Development
To clone the repository and set up the dependencies, run the following:
```bash
git clone https://github.com/mattrayner/alexa_verifier.git
cd alexa_verifier
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
[AlexaVerifier][alexa_verifier] is licensed under the [MIT][info-license].


## Code of Conduct
Everyone interacting in the AlexaVerifier project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct][code_of_conduct].

[alexa_verifier]:  https://github.com/sidoh/alexa_verifier
[ruby]:            http://ruby-lang.org
[rack]:            https://rack.github.io
[rails]:           http://rubyonrails.org
[sinatra]:         http://sinatrarb.com
[rspec]:           http://rspec.info
[code_of_conduct]: https://github.com/mattrayner/alexa_verifier/blob/master/CODE_OF_CONDUCT.md

[info-gem]:   https://rubygems.org/gems/alexa_verifier
[shield-gem]: https://img.shields.io/gem/v/alexa_verifier.svg

[info-travis]:   https://travis-ci.org/sidoh/alexa_verifier
[shield-travis]: https://img.shields.io/travis/sidoh/alexa_verifier.svg

[info-coveralls]:   https://coveralls.io/github/sidoh/alexa_verifier
[shield-coveralls]: https://img.shields.io/coveralls/github/sidoh/alexa_verifier.svg

[info-license]:   https://github.com/sidoh/alexa_verifier/blob/master/LICENSE
[shield-license]: https://img.shields.io/badge/license-MIT-blue.svg
