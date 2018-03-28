# coding: utf-8

# place ONLY runtime dependencies in here (in addition to metadata)
require File.expand_path("../lib/version", __FILE__)

Gem::Specification.new do |s|
  s.name          = "gem_of"
  s.authors       = ["Puppet, Inc.", "Eric Thompson"]
  s.email         = ["qa@puppet.com"]
  s.summary       = "Puppet Gem testing Gems, RakeTasks"
  s.description   = "Puppet common tools and setup, for testing, building \
  and documenting ruby projects"
  s.homepage      = "https://github.com/puppetlabs/gem_of"
  s.version       = GemOf::Version::STRING
  s.license       = "Apache-2.0"
  s.files         = Dir["CONTRIBUTING.md", "LICENSE.md", "MAINTAINERS",
                        "README.md", "lib/**/*", "docs/**/*"]
  s.required_ruby_version = ">= 2.0.0"
end
