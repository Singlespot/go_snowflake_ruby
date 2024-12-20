# frozen_string_literal: true

require_relative "lib/go_snowflake_ruby/version"

Gem::Specification.new do |spec|
  spec.name = "go_snowflake_ruby"
  spec.version = GoSnowflakeRuby::VERSION
  spec.authors = ["Guillaume GILLET"]
  spec.email = ["guillaume.gillet@singlespot.com"]

  spec.summary = "A binding ruby lib with the snowflake go driver"
  spec.description = "A binding ruby lib with the snowflake go driver"
  spec.homepage = "https://github.com/Singlespot"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    Dir.glob("**/*").select { |f| File.file?(f) }.reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ sig/ .git Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.extensions    = ["ext/go_snowflake/extconf.rb"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency 'rake', '~> 13.0'
  spec.add_dependency 'ffi', '~> 1.15'

  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rake-compiler'
  spec.add_development_dependency 'rubocop'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
