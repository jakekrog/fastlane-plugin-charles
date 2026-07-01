lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/charles/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-charles'
  spec.version       = Fastlane::Charles::VERSION
  spec.author        = 'Jake Krog'

  spec.summary       = 'Run Charles HTTP proxy'
  spec.description   = 'Runs Charles Proxy from a fastlane lane, generating its .config file at runtime from a simplified YAML config that a team can commit and share, instead of hand-editing the XML Charles itself exports.'
  spec.homepage      = "https://github.com/jakekrog/fastlane-plugin-charles"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE CHANGELOG.md)
  spec.require_paths = ['lib']
  spec.metadata = {
    'bug_tracker_uri'       => 'https://github.com/jakekrog/fastlane-plugin-charles/issues',
    'changelog_uri'         => 'https://github.com/jakekrog/fastlane-plugin-charles/blob/main/CHANGELOG.md',
    'rubygems_mfa_required' => 'true',
    'source_code_uri'       => 'https://github.com/jakekrog/fastlane-plugin-charles'
  }
  spec.required_ruby_version = '>= 3.0'

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  # spec.add_dependency 'your-dependency', '~> 1.0.0'
end
