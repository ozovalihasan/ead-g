lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name = 'ead'
  s.version = '0.4.0'
  s.summary = 'Compiler for JSON files created by EAD'
  s.description = 'The compiler updates/creates models and associations, used in a Ruby on Rails project, defined by EAD automatically.'
  s.authors = ['Hasan Ozovali']
  s.email = 'ozovalihasan@gmail.com'
  s.require_paths = ['lib']
  s.homepage =
    'https://rubygems.org/gems/ead'
  s.license = 'MIT'
  s.files = Dir.glob('{bin,lib}/**/*')
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.required_ruby_version = '>= 2.7.2'

  s.add_runtime_dependency 'rest-client', '~> 2.0', '>= 2.0.2'

  s.add_development_dependency 'activesupport', '~> 5.2'
  s.add_development_dependency 'bundler', '~> 2.2'
  s.add_development_dependency 'pry', '~> 0.14.1'
  s.add_development_dependency 'rspec', '~> 3.10'
  s.add_development_dependency 'rubocop', '~> 1.13'
  s.metadata['rubygems_mfa_required'] = 'true'
end
