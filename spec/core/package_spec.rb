RSpec.describe Latexmath::Core::Package do
  context 'Package' do
    it '#parse_prototype' do
      tokens = Latexmath::Core::Package.new.parse_prototype('\case{}{}')
      expect(
        tokens.first.to_s
      ).to eq("\\case")
      expect(
        tokens.first.catcode
      ).to eq(16)
    end
    it 'Aas' do
      aas = Latexmath::Packages::Aas.new(Latexmath::Core::Package.new)
      expect(aas).to eq(true)
    end
  end
end
