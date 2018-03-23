# gem_of
Gem testing gems, rake tasks

Gemfiles are typically used solely for gems in development and testing. Are you tired of copypastaing the same Gems and rake tasks around to various projects, only to have to update them all later?

use the gem_of gems!

we bring you:

rake, rototiller, rspec, rubocop, simplecov, yardstick, markdown, flay, flog, roodi, rubycritic, and coveralls for all your dev and unit testing needs.

we bring you: beaker for your system testing needs, AND we ensure the bundle will install consistently across ruby versions by pinning old dependencies that don't seem to like following semver rules.

later we'll supply a bunch of canned rake tasks to bring this all together from the CLI or CI (see our Rakefile)

## currently installed gems

* [rake](https://github.com/ruby/rake): "A make-like build utility for Ruby."
* [rototiller](https://github.com/puppetlabs/rototiller): "A Rake helper library for command-oriented tasks."
* [rspec](http://rspec.info/): "Behaviour Driven Development for Ruby."
* [rubocop](https://github.com/bbatsov/rubocop): "A Ruby static code analyzer, based on the community Ruby style guide."
* [simplecov](https://github.com/colszowka/simplecov): "Code coverage for Ruby 1.9+ with a powerful configuration library and automatic merging of coverage across test suites."
* [yardstick](https://github.com/dkubb/yardstick): "A tool for verifying YARD documentation coverage."
* [markdown](https://en.wikipedia.org/wiki/Markdown): "A lightweight markup language with plain text formatting syntax."
* [flay](https://github.com/seattlerb/flay): "Flay analyzes code for structural similarities."
* [flog](https://github.com/seattlerb/flog): "Flog reports the most tortured code in an easy to read pain report."
* [roodi](https://github.com/roodi/roodi): "Ruby Object Oriented Design Inferometer"
* [rubycritic](https://github.com/whitesmith/rubycritic): "A Ruby code quality reporter."
* [coveralls](https://docs.coveralls.io/): "Coveralls is a web service to help you track your code coverage over time, and ensure that all your new code is fully covered."

## locally install this gem
you can't put this in your Gemfile, because we need to use it to form your Gemfile
```
gem install --local gem_of
```
or:
```
clone git@github.com:puppetlabs/gem_of.git
cd gem_of
bundle install
be rake gem:build
be rake gem:install:local
```

## In your Gemfile
```
require 'gem_of'

eval(GemOf::Gems.new, binding)
```
