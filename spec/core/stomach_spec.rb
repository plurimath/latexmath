RSpec.describe Latexmath::Core::Stomach do
  context 'Stomach' do
    it '#new' do
      stomach = Latexmath::Core::Stomach.new
      expect(stomach.gullet).to be_a_kind_of(Latexmath::Core::Gullet)
    end
  end
end
