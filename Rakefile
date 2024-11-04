# frozen_string_literal: true

require "bundler/gem_tasks"
require 'rake/testtask'

# Define directories and files
EXT_DIR = File.expand_path('ext')
LIB_DIR = File.expand_path('lib')
CLEAN.include(
  File.join(EXT_DIR, '**/*.o'),
  File.join(EXT_DIR, '**/*.so'),
  File.join(EXT_DIR, '**/*.h'),
  File.join(EXT_DIR, '**/*.sum'),
  File.join(EXT_DIR, '**/*.mod'),
  File.join(EXT_DIR, '*.bundle')
)
CLOBBER.include('**/Makefile', '**/mkmf.log')

require "rubocop/rake_task"

RuboCop::RakeTask.new

# Task to clean the build artifacts
task :clean do
  Rake::Task[:clobber].invoke
end

# Task to build the extension
task build: :clean do
  Dir.chdir(EXT_DIR) do
    sh 'ruby go_snowflake/extconf.rb'
    sh 'make'
  end
end

# Define the test task with build dependency
Rake::TestTask.new do |t|
  t.pattern = "test/**/test_*.rb"
  t.libs << 'lib'
  t.verbose = true
  t.warning = true
end

# Add the build task as a prerequisite to the test task
task test: [:clean, :build]

task default: %i[test rubocop]
