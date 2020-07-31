RSpec.describe Latexmath do
  it "has a version number" do
    expect(Latexmath::VERSION).not_to be nil
  end

  let(:simple_1) { '\varepsilon = \frac{1}{2} ( J + J^t )' }

  %w(simple_1).each do |name|
    it "parses #{name}" do
      expect(Latexmath.parse(send(name)).to_mathml).to eq(Latexmath::Requirements[:latexml].convert(send(name)))
    end
  end

end
