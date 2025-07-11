# frozen_string_literal: true

require_relative 'lib/adapay/version'

Gem::Specification.new do |spec|
  spec.name          = 'adapay'
  spec.version       = Adapay::VERSION
  spec.authors       = ['lanzhiheng']
  spec.email         = ['lanzhihengrj@gmail.com']

  spec.summary       = 'Gem for Adapay'
  spec.description   = 'Gem for Adapay'
  spec.homepage      = 'https://www.adapay.tech/'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = 'https://www.adapay.tech/'
  spec.metadata['source_code_uri'] = 'https://github.com/lanzhiheng/adapay'
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'rest-client', '~> 2.1'
end
