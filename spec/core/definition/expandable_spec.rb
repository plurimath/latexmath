RSpec.describe Latexmath::Core::Definition::Expandable do
  context 'Expandable' do
    it '#new' do
      expandable = Latexmath::Core::Definition::Expandable.new(
        Latexmath::Core::Token.new("\\case", 16),
        "\\case{}{}",
        "\\ensuremath{\\text@frac{#1}{#2}}",
        {}
      )
      expect(
        expandable
      ).to eq(['t', 'e', 's', 't'])
    end
  end
end
