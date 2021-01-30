# frozen_string_literal: true

require_relative 'lib/prubot/version'

Gem::Specification.new do |spec|
  spec.name          = 'prubot'
  spec.version       = Prubot::VERSION
  spec.authors       = ['Jimmy Bradshaw']
  spec.email         = ['james.g.bradshaw@gmail.com']

  spec.summary       = 'GitHub Apps to automate and improve your workflow.'
  spec.homepage      = 'https://github.com/bradshjg/prubot'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.pkg.github.com'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'jwt', '~> 2.2'
  spec.add_dependency 'octokit', '~> 4.0'
  spec.add_dependency 'rack', '~> 2.2'
end
