# gem_of
Gem testing gems, rake tasks

Gemfiles are typically used solely for gems in development and testing. Are you tired of copypastaing the same Gems and rake tasks around to various projects, only to have to update them all later?

use the gem_of gems!

we bring you:
* rake, rototiller, rspec, rubocop, simplecov, yardstick, markdown, rubycritic, and coveralls for all your dev and unit testing needs.
* beaker for your system testing needs, AND we ensure the bundle will install consistently across ruby versions by pinning old dependencies that don't seem to like following semver rules.

later we'll supply a bunch of canned rake tasks to bring this all together from the CLI or CI (see our Rakefile).

## currently installed gems
### dev and unit testing
* [coveralls](https://docs.coveralls.io/): "Coveralls is a web service to help you track your code coverage over time, and ensure that all your new code is fully covered."
* [markdown](https://en.wikipedia.org/wiki/Markdown): "A lightweight markup language with plain text formatting syntax."
* [rake](https://github.com/ruby/rake): "A make-like build utility for Ruby."
* [rototiller](https://github.com/puppetlabs/rototiller): "A Rake helper library for command-oriented tasks."
* [rspec](http://rspec.info/): "Behaviour Driven Development for Ruby."
* [rubocop](https://github.com/bbatsov/rubocop): "A Ruby static code analyzer, based on the community Ruby style guide."
* [simplecov](https://github.com/colszowka/simplecov): "Code coverage for Ruby 1.9+ with a powerful configuration library and automatic merging of coverage across test suites."
* [yardstick](https://github.com/dkubb/yardstick): "A tool for verifying YARD documentation coverage."

### system testing
* [beaker](https://github.com/puppetlabs/beaker): "Beaker is a test harness focused on acceptance testing via interactions between multiple (virtual) machines."
* [beaker-hostgenerator](https://github.com/puppetlabs/beaker-hostgenerator): "Beaker Host Generator is a command line utility designed to generate beaker host config files using a compact command line SUT specification."

## locally install this gem
If you are using gem_of for its super-sweet opinion on dependency management for gem development and testing, you can't just add gem_of in your Gemfile, because we need to use it to _form_ your Gemfile. So you can either install it locally (as below), or use gem_of as a submodule.

```
gem install --local gem_of
```
or (use as a submodule):
```
clone git@github.com:puppetlabs/gem_of.git
cd gem_of
bundle install
bundle exec rake gem:build
bundle exec rake gem:install:local
```
you should probably pin your submodule version to a tag of a released,stable version of gem_of.
## In your Gemfile
```
require 'gem_of'

eval(GemOf::Gems.new, binding)
```

## In your Rakefile
gem_of distributes itself into your Gemfile, so if it's installed locally, as above, then the bundle for your other project will have it, and the rake tasks:
```
require "gem_of/rake_tasks"

GemOf::RakeTasks.new
```
