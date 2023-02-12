# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'capistrano-anycable-systemd'
  spec.version = '0.0.1'
  spec.authors = ['Alfonso Lee']
  spec.email = ['onesup.lee@gmail.com']
  spec.description = %q{anycable integration for Capistrano}
  spec.summary = %q{anycable integration for Capistrano systemd}
  spec.homepage = 'https://github.com/onesup/capistrano-anycable-systemd'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 2.5'

  spec.files = Dir.glob('lib/**/*') + %w(README.md CHANGELOG.md LICENSE.txt)
  spec.require_paths = ['lib']

  spec.add_dependency 'capistrano', '~> 3.17'
  spec.add_dependency 'capistrano-bundler', '~> 2.1'
  spec.add_dependency 'anycable-rails', '~> 1.3'
  spec.post_install_message = %q{
    Please see README.md
  }
end
