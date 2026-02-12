# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

task default: :spec

# Run all tests (unit + integration)
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--format documentation'
end

# Run only unit tests (mocked, no Docker required)
RSpec::Core::RakeTask.new(:spec_unit) do |t|
  t.rspec_opts = '--format documentation --tag ~integration'
end

# Run only integration tests (requires Docker servers)
RSpec::Core::RakeTask.new(:spec_integration) do |t|
  t.rspec_opts = '--format documentation --tag integration'
end

# Integration tests with Docker management
desc 'Run integration tests with Docker cleanup'
task :integration do
  puts "\n==> Cleaning up Docker environment..."
  system('docker-compose down -v')

  puts "\n==> Starting Docker servers..."
  system('docker-compose up -d')

  puts "\n==> Waiting for servers to be ready..."
  sleep 10

  puts "\n==> Running integration tests..."
  result = system('bundle exec rspec --format documentation --tag integration')

  puts "\n==> Cleaning up Docker environment..."
  system('docker-compose down -v')

  exit(1) unless result
end

# Docker management tasks
namespace :docker do
  desc 'Start Docker servers'
  task :up do
    system('docker-compose down -v')
    system('docker-compose up -d')
    puts 'Docker servers started. Waiting 10 seconds for initialization...'
    sleep 10
    puts 'Docker servers ready!'
  end

  desc 'Stop Docker servers'
  task :down do
    system('docker-compose down -v')
  end

  desc 'View Docker logs'
  task :logs do
    system('docker-compose logs -f')
  end
end
