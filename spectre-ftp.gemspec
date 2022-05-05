Gem::Specification.new do |spec|
  spec.name          = 'spectre-ftp'
  spec.version       = '1.0.0'
  spec.authors       = ['Christian Neubauer']
  spec.email         = ['christian.neubauer@ionos.com']

  spec.summary       = 'FTP module for spectre'
  spec.description   = 'Adds FTP functionality to the spectre framework'
  spec.homepage      = 'https://github.com/ionos-spectre/spectre-ftp'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.0.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org/'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ionos-spectre/spectre-ftp'
  spec.metadata['changelog_uri'] = 'https://github.com/ionos-spectre/spectre-ftp/src/master/CHANGELOG.md'

  spec.files        += Dir.glob('lib/**/*')

  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'net-sftp', '~> 3.0.0'
  spec.add_runtime_dependency 'spectre-core', '>= 1.8.4'
end
