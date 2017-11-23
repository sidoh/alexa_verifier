require_relative '../spec_helper'

RSpec.describe AlexaVerifier::Configuration do
  attribute_array = [
    :enabled,
    :verify_uri,
    :verify_timeliness,
    :verify_certificate,
    :verify_signature
  ]

  let(:attributes) { attribute_array }

  # Convert our attributes into their respective helper functions.
  #
  # i.e. :enabled => :enabled?, :verify_uri => :verify_uri?, etc.
  let(:helper_methods) do
    attributes.map { |attribute| (attribute.to_s + '?').to_sym }
  end

  describe '#initialize' do
    it 'enables all settings by default' do
      attributes.each { |attribute| expect(subject.send(attribute)).to eq(true) }
    end
  end

  it_behaves_like 'it has configuration options', attribute_array

  describe '#enabled' do
    context 'when set to false' do
      let(:disabled_subject) do
        instance = subject
        instance.enabled = false

        instance
      end

      it 'instance answers all helper methods with false' do
        helper_methods.each { |method| expect(disabled_subject.send(method)).to eq(false) }
      end
    end
  end
end