module Latexmath
  module Core
    module Definition
      class Expandable
        attr_reader :cs
        def initialize(cs, parameters, expansion, options)
          @cs = cs

          if expansion.is_a?(Latexmath::Core::Tokens)
            # Fatal('misdefined', $cs, $source, "Expansion of '" . ToString($cs) . "' has unbalanced {}",
            #   "Expansion is " . ToString($expansion)) unless $expansion->isBalanced;
            expansion = Latexmath::Core::Tokens.new(expansion.unlist.map(&:without_dont_expand))
            # If expansion is Tokens, and no arguments, we're a "trivial macro"
            unless parameters
              trivexpansion = expansion.substitute_parameters
            end
          end
        end
      end
    end
  end
end
