require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require_relative 'lib/latexmath'

RSpec::Core::RakeTask.new(:spec)

desc 'Generate and write MathML fixtures'
task 'create-mathml-fixtures' do
  records = Dir.glob('spec/fixtures/*/*.tex')

  records.each do |file|
    tex = File.read("./#{file}")
    tokens = Latexmath::Tokenizer.new(tex).tokenize
    aggr = Latexmath::Aggregator.new(tokens).aggregate

    File.write("./#{file.chomp('.tex')}.html", Latexmath::Converter.new(aggr).convert)
  end
end

task 'build-opal' do
  require 'opal'
  require 'erb'
  require 'json'

  b = Opal::Builder.new

  b.append_paths __dir__ + '/lib'
  b.append_paths __dir__ + '/opal'
  b.use_gem 'htmlentities'

  build = b.build('latexmath-opal').to_s
  # This is a hack intended for ExecJS to work properly.
  build = build.gsub('Object freezing is not supported by Opal', '')

  FileUtils.mkdir_p 'dist'
  File.write('dist/latexmath.js', build)
end

task 'spec-opal' => 'build-opal' do
  ENV['TEST_OPAL'] = '1'
  Rake::Task['spec'].execute
  ENV.delete 'TEST_OPAL'
end

def read_symbols(input)
  @symbols = {}
  File.readlines(input).each do |line|
    next if line.start_with?('#')

    columns = line.chop.split('^')
    _unicode = columns[0]
    latex = columns[2]
    unicode_math = columns[3]

    @symbols[latex] = _unicode if latex && !@symbols.include?(latex)
    @symbols[unicode_math] = _unicode if unicode_math && !@symbols.include?(unicode_math)

    matches = columns[-1].match(/=\s+(\\[^,^ ]+),?/)
    if matches
      @symbols[matches[1]] = _unicode unless @symbols[matches[1]]
    end
  end
  @symbols
end

directory 'lib/latexmath/constants'
file 'lib/latexmath/constants/symbols.rb' => [
  'lib/latexmath/constants',
  'lib/unimathsymbols.txt'
  ] do |file|
  symbols = read_symbols(file.prerequisites.last)

  File.open(file.name, "w+") do |f|
    f.puts <<~HERE
    module Latexmath
      module Constants
        SYMBOLS = {
    HERE

    @symbols.each_pair do |k,v|
      f.puts("     '#{k.to_s}' => '#{v}',")
    end

    f.puts <<~HERE
        }.freeze
      end
    end
    HERE
  end
end

Rake::Task['build'].enhance ['lib/latexmath/constants/symbols.rb']
Rake::Task[:spec].enhance ['lib/latexmath/constants/symbols.rb']

task default: [:spec, 'spec-opal']
