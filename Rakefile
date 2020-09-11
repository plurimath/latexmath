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

task default: [:spec, 'spec-opal']
