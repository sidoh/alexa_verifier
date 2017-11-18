RSpec.shared_examples 'a StandardError' do
  it 'behaves like a StandardError' do
    error = described_class.new('foo')
    expect(error.message).to eq('foo')
  end
end