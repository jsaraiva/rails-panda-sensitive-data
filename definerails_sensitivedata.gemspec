$LOAD_PATH.push File.expand_path('lib', __dir__)

require "definerails_sensitivedata/version"

Gem::Specification.new do |s|
  s.required_ruby_version = '>= 3.2'

  s.name        = "definerails_sensitivedata"
  s.version     = DefineRails::SensitiveData::VERSION
  s.authors     = ["DefineScope"]
  s.email       = ["info@definescope.com"]
  s.homepage    = "https://www.definescope.com"
  s.summary     = "Code that Rails applications use for dealing with sensitive data (GDPR)."
  s.description = "Code that Rails applications use for dealing with sensitive data (GDPR)."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile"]
  # s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 7.0.0"

  s.metadata["rubygems_mfa_required"] = "true"
end
