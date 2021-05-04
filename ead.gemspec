# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name        = 'ead'
  s.version     = '0.1.0'
  s.summary     = "Compiler for JSON files created by EAD"
  s.description = "The compiler updates/creates models and associations, used in a Ruby on Rails project, defined by EAD automatically."
  s.authors     = ["Hasan Ozovali"]
  s.email       = 'ozovalihasan@gmail.com'
  s.require_paths = ["lib"]
  s.homepage    =
    'https://rubygems.org/gems/ead'
  s.license       = 'MIT'
  s.files         = Dir.glob("{bin,lib}/**/*")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
end

