RSpec.describe Latexmath::Core do
  context 'Core' do
    it '#new' do
      core = Latexmath::Core.new(verbosity: 1)
      expect(
        core
      ).to eq(true)
    end
  end
end
