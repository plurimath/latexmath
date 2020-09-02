require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task 'build-opal' do
  require 'opal'
  require 'erb'
  require 'json'

  b = Opal::Builder.new

  b.append_paths __dir__+'/lib'
  b.append_paths __dir__+'/opal'
  b.use_gem 'htmlentities'

  FileUtils.mkdir_p 'dist'
  File.write('dist/latexmath.js', b.build('latexmath-opal').to_s)
end

task 'spec-opal' => 'build-opal' do
  ENV['TEST_OPAL'] = '1'
  Rake::Task['spec'].execute
  ENV.delete 'TEST_OPAL'
end

task default: :spec
