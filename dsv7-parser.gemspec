# frozen_string_literal: true

require_relative 'lib/dsv7/parser/version'

Gem::Specification.new do |spec|
  spec.name          = 'dsv7-parser'
  spec.version       = Dsv7::Parser::VERSION
  spec.authors       = ['dsv7-parser authors']
  spec.email         = ['devnull@example.com']

  spec.summary       = 'SAX parser for the DSV7 swim file format'
  spec.description   = 'Ruby gem skeleton for a DSV7 SAX parser.'
  spec.homepage      = 'https://example.com/dsv7-parser'
  spec.license       = 'MIT'

  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|features)/}) }
  end

  spec.require_paths = ['lib']

  # Runtime dependencies (none yet)
  # spec.add_dependency "nokogiri", ">= 1.14"

  # Development dependencies are declared in Gemfile
end
