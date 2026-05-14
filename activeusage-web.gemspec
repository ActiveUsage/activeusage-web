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

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ActiveUsage/activeusage-web/tree/#{ActiveUsage::Web::VERSION}"
  spec.metadata["changelog_uri"] = "https://github.com/ActiveUsage/activeusage-web/tree/#{ActiveUsage::Web::VERSION}/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  end

  spec.add_dependency "rails", ">= 7.2.0"
end
