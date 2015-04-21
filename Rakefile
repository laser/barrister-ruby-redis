require 'bundler/gem_tasks'
require 'rake/testtask'

desc 'Default: run all tests'
task :default => :test

desc 'Run unit tests.'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end
