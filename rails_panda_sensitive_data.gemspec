$LOAD_PATH.push File.expand_path("lib", __dir__)

require "rails_panda_sensitive_data/version"

Gem::Specification.new do |s|
  s.required_ruby_version = ">= 3.2"

  s.name = "rails-panda-sensitive-data"
  s.version = RailsPanda::SensitiveData::VERSION
  s.authors = ["João Saraiva"]
  s.email = ["panda@bigbadpanda.com"]
  s.homepage = "https://github.com/jsaraiva/rails-panda-sensitive-data"
  s.summary = "Code that Rails applications use for dealing with sensitive data (e.g., GDPR)."
  s.description = "Code that Rails applications use for dealing with sensitive data (e.g., GDPR)."
  s.license = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile"]
  # s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 7.0.0"

  s.metadata["rubygems_mfa_required"] = "true"
end
