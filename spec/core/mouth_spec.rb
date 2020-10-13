RSpec.describe Latexmath::Core::Mouth do
  context 'Mouth' do
    it '#split_chars' do
      tokens = Latexmath::Core::Mouth.new('x').split_chars('test')
      expect(
        tokens
      ).to eq(['t', 'e', 's', 't'])
    end
  end
end
