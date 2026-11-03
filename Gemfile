source 'https://rubygems.org'

# Specify your gem's dependencies in latexmath.gemspec
gemspec

gem 'byebug'
gem 'pry'
gem 'rake', '~> 12.0'
gem 'rspec', '~> 3.0'
gem 'rubocop'

# The artifact job in CI recompiles with the compiler the committed artifact
# records (artifacts/latex.checksums.txt, compiler_version).
gem 'parsanol', ENV['PARSANOL_VERSION'] if ENV['PARSANOL_VERSION']
