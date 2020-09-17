#======================================================================
# 2.17.3 Fractions

# \case{1}{2} == textstyle fraction
# AND, apparently allowed in text mode!
# DefMacro('\case{}{}', '\ensuremath{\text@frac{#1}{#2}}');
# DefConstructor('\text@frac ScriptStyle ScriptStyle',
#   "<ltx:XMApp>"
#     . "<ltx:XMTok meaning='divide' role='FRACOP' mathstyle='text'/>"
#     . "<ltx:XMArg>#1</ltx:XMArg><ltx:XMArg>#2</ltx:XMArg>"
#     . "</ltx:XMApp>",
#   sizer => sub { fracSizer($_[0]->getArg(1), $_[0]->getArg(2)); });
# Let('\slantfrac', '\case');


module Latexmath
  module Packages
    class Aas
      #======================================================================
      # 2.17.3 Fractions

      # \case{1}{2} == textstyle fraction
      # AND, apparently allowed in text mode!
      def initialize(package)
        package.macro('\case{}{}', '\ensuremath{\text@frac{#1}{#2}}')
      end
    end
  end
end
