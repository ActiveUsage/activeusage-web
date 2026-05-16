require_relative "lib/active_usage/web/version"

Gem::Specification.new do |spec|
  spec.name        = "activeusage-web"
  spec.version     = ActiveUsage::Web::VERSION
  spec.authors     = [ "Tomasz Kowalewski" ]
  spec.email       = [ "me@tkowalewski.pl" ]
  spec.homepage    = "https://activeusage.com"
  spec.summary     = "Rails Engine dashboard for ActiveUsage."
  spec.description = "Local-first dashboard for exploring ActiveUsage cost estimates inside a Rails app."
  spec.license     = "MIT"

  spec.metadata["allowed_push_host"]  = "https://rubygems.org"
  spec.metadata["homepage_uri"]        = spec.homepage
  spec.metadata["source_code_uri"]     = "https://github.com/ActiveUsage/activeusage-web"
  spec.metadata["changelog_uri"]       = "https://github.com/ActiveUsage/activeusage-web/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"]     = "https://github.com/ActiveUsage/activeusage-web/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  end

  spec.add_dependency "rails", ">= 7.2.0"
  spec.add_dependency "activeusage", "~> 0.1"
end
