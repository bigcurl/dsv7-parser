# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'
require 'rdoc/task'

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

desc 'Generate RDoc documentation into doc/'
RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.main = 'README.md'
  rdoc.title = 'dsv7-parser'
  rdoc.rdoc_files.include('README.md', 'lib/**/*.rb')
end
