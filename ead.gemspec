lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name = 'ead'
  spec.version = '0.4.5'
  spec.summary = 'Compiler for JSON files created by EAD'
  spec.description = 'The compiler updates/creates models and associations, used in a Ruby on Rails project, defined by EAD automatically.'
  spec.authors = ['Hasan Ozovali']
  spec.email = 'ozovalihasan@gmail.com'
  spec.require_paths = ['lib']
  spec.homepage = 'https://github.com/ozovalihasan/ead-g'
  spec.license = 'MIT'
  spec.files = Dir.glob('{bin,lib}/**/*')
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.required_ruby_version = '>= 2.7.2'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.add_runtime_dependency 'rest-client', '~> 2.0', '>= 2.0.2'

  spec.add_development_dependency 'activesupport', '~> 5.2'
  spec.add_development_dependency 'bundler', '~> 2.2'
  spec.add_development_dependency 'pry', '~> 0.14.1'
  spec.add_development_dependency 'rspec', '~> 3.10'
  spec.add_development_dependency 'rubocop', '~> 1.13'
  spec.add_development_dependency 'simplecov', '~> 0.21.2'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
