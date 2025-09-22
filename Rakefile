# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

task default: :test

desc 'Run RuboCop'
RuboCop::RakeTask.new(:rubocop)

desc 'Run all linters'
task lint: :rubocop
