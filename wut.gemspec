# wut.gemspec

Gem::Specification.new do |spec|
  spec.name                  = "wut"
  spec.version               = "1.0.0"
  spec.authors               = ["Eric Beland"]

  spec.summary               = "Adds useful print debug statements to inspect and output variable values. A replacement for puts debugging."
  spec.description           = <<~DESC
    wut is a small library that adds simple, print debugging commands. 
    It makes it easy to inspect and output current variable values without cluttering your code,
    acting as an upgrade for puts-based debugging. It uses only Ruby’s built-in features (no extra dependencies).
  DESC

  # Update these to your actual wut repository URLs
  spec.homepage              = "https://github.com/ericbeland/wut"
  spec.metadata["homepage_uri"]     = spec.homepage
  spec.metadata["source_code_uri"]  = "https://github.com/ericbeland/wut"

  spec.required_ruby_version = ">= 3.0.0"

  # Files to include in the gem
  # spec.files = Dir.chdir(__dir__) do
  #   `git ls-files -z`.split("\x0").reject do |f|
  #     # Exclude gemspec itself and any undesired directories/files
  #     (File.expand_path(f) == __FILE__) ||
  #       f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
  #   end
  # end
  spec.require_paths = ["lib"]

  # Development dependencies
  spec.add_development_dependency "amazing_print", "~> 1.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "yard", "~> 0.9"
end
