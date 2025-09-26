# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'
begin
  require 'yard'
  require 'yard/rake/yardoc_task'
rescue LoadError
  # YARD is a dev dependency; tasks are available when installed
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  # Do not echo the underlying ruby command with the test file list
  t.verbose = false
end

# Run tests and lint by default
task default: %i[test lint]

desc 'Run RuboCop'
RuboCop::RakeTask.new(:rubocop)

desc 'Run all linters'
task lint: :rubocop

desc 'CI: run tests and lint'
task ci: %i[test lint]

  if defined?(YARD)
    desc 'Generate YARD documentation into doc/'
    YARD::Rake::YardocTask.new(:yard) do |t|
    # Parse only Ruby sources; README is provided via --readme for markup rendering
    t.files = FileList['lib/**/*.rb']
    t.options = [
      '--no-cache',
      '--markup', 'markdown',
      '--markup-provider', 'kramdown',
      '--readme', 'README.md',
      '--hide-api', 'private'
    ]
  end
  # Back-compat target for `rake doc`
  task doc: :yard
  # Generate full internal docs (includes @api private and private methods)
  desc 'Generate full YARD docs (including private API) into doc-internal/'
  YARD::Rake::YardocTask.new(:yard_full) do |t|
    t.files = FileList['lib/**/*.rb']
    t.options = [
      '--no-cache',
      '--markup', 'markdown',
      '--markup-provider', 'kramdown',
      '--readme', 'README.md',
      '--private',
      '-o', 'doc-internal'
    ]
  end
  task 'docs:full' => :yard_full
  task docs: :yard
end
