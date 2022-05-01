$:.push File.expand_path('../lib', __FILE__)

require 'definerails_sensitivedata/version'

Gem::Specification.new do |s|
  s.name        = 'definerails_sensitivedata'
  s.version     = DefineRails::SensitiveData::VERSION
  s.authors     = ['DefineScope']
  s.email       = ['info@definescope.com']
  s.homepage    = 'https://www.definescope.com'
  s.summary     = 'Code that DefineScope\'s Rails applications use for dealing with sensitive data (GDPR).'
  s.description = 'Code that DefineScope\'s Rails applications use for dealing with sensitive data (GDPR).'
  s.license     = 'MIT'

  s.files = Dir["{app,config,db,lib}/**/*", 'LICENSE', 'Rakefile']
  # s.test_files = Dir["test/**/*"]

  s.add_dependency 'rails'#, '>= 5.1.2'

  # Get the 'attr_encypted' gem
  s.add_dependency 'attr_encrypted'
end
