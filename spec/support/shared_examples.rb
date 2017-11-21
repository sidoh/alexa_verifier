RSpec.shared_examples 'a StandardError' do
  it 'behaves like a StandardError' do
    error = described_class.new('foo')
    expect(error.message).to eq('foo')
  end
end

RSpec.shared_examples 'it has configuration options' do |attributes|
  attributes.each do |attribute|
    describe "##{attribute.to_s}?" do
      context "with ##{attribute} set to false" do
        let(:instance) do
          instance = described_class.new
          instance.send("#{attribute}=".to_sym, false)

          instance
        end

        it 'answers with false' do
          expect(instance.send("#{attribute}?".to_sym)).to eq(false)
        end
      end

      context "with ##{attribute} set to true" do
        let(:instance) do
          instance = described_class.new
          instance.send("#{attribute}=".to_sym, true)

          instance
        end

        it 'answers with true' do
          expect(instance.send("#{attribute}?".to_sym)).to eq(true)
        end
      end
    end
  end
end
