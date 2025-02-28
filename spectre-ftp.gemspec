# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'spectre-ftp'
  spec.version       = '2.0.0'
  spec.authors       = ['Christian Neubauer']
  spec.email         = ['christian.neubauer@ionos.com']

  spec.summary       = 'Standalone FTP wrapper compatible with spectre'
  spec.description   = 'A simple FTP wrapper for nice readability. Is compatible with spectre-core.'
  spec.homepage      = 'https://github.com/ionos-spectre/spectre-ftp'
  spec.license       = 'GPL-3.0-or-later'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.1.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ionos-spectre/spectre-ftp'
  spec.metadata['changelog_uri'] = 'https://github.com/ionos-spectre/spectre-ftp/src/master/CHANGELOG.md'
  spec.metadata['allowed_push_host'] = 'https://rubygems.pkg.github.com/ionos-spectre'

  spec.files        += Dir.glob('lib/**/*')
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'net-ftp'
  spec.add_runtime_dependency 'net-sftp'
end
