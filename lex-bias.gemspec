# frozen_string_literal: true

require_relative 'lib/legion/extensions/bias/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-bias'
  spec.version       = Legion::Extensions::Bias::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Bias'
  spec.description   = 'Cognitive bias detection and correction for brain-modeled agentic AI'
  spec.homepage      = 'https://github.com/LegionIO/lex-bias'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-bias'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-bias'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-bias'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-bias/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-bias.gemspec Gemfile LICENSE]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
