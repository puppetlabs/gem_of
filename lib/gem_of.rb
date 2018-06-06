require "rubygems" # for Gem Versioning methods

# Namespace for Gem methods
module GemOf
  # produce a list of gems for use in a gems Gemfile
  # @return [String] a string of Gemfile dependencies for a Gemfile to eval
  # @example eval this in your Gemfile in its binding
  #   eval(GemOf.gems, binding)
  # @api public
  class Gems
    def initialize
      set_gem_versions

      @gem_code = <<-HEREDOC
      source "https://rubygems.org"
      # place all development, system_test, etc dependencies here

      # lint/unit tests
      gem "rake"
      # ensure downstream projects get gem_of for rake tasks
      gem "gem_of",     #{location_of_interp(@gemof_version)}
      gem "rototiller", "~> 1.0"
      gem "rspec",      "~> 3.4.0"
      gem "rubocop",    "~> 0.49.1" # used in tests. pinned
      gem "simplecov",  "~> 0.14.0" # used in tests
      gem "yardstick",  "~> 0.9.0"  # used in tests
      gem "markdown",   "~> 0"
      gem "flay",       "~> 2.10.0" # used in tests
      gem "flog",       "~> 4.6.0"  # used in tests
      gem "roodi",      "~> 5.0.0"  # used in tests
      gem "rubycritic"
      gem "coveralls",  require: false # used in tests

      group :system_tests do
        gem "beaker",         #{location_of_interp(@beaker_version)}
        gem "beaker-hostgenerator"
        gem "beaker-abs",     #{location_of_interp(@beaker_abs_version)}
        gem "nokogiri",       "#{@nokogiri_version}"
        gem "public_suffix",  "#{@public_suffix_version}"
        #gem "activesupport", "#{@activesupport_version}"
      end

      local_gemfile = "Gemfile.local"
      if File.exists? local_gemfile
        eval(File.read(local_gemfile), binding)
      end

      user_gemfile = File.join(Dir.home,".Gemfile")
      if File.exists? user_gemfile
        eval(File.read(user_gemfile), binding)
      end
      HEREDOC
    end

    # output the gem_code of this class as a string
    #   implements both #to_str and #to_s for implicit conversions
    # @return [String] of our gem_code
    # @api public
    def to_str
      @gem_code
    end
    alias to_s to_str

    private

    # rubocop:disable Metrics/MethodLength
    # Set instance params for the various gem versions we need based upon ruby
    #   should really only be used in above, will change, over time
    # @api private
    def set_gem_versions
      # restrict gems to enable ruby versions

      @public_suffix_version = "~> 1" # any
      @activesupport_version = "~> 1" # any
      @gemof_version         = ENV["GEMOF_VERSION"] || "~> 0" # any
      @beaker_abs_version    = ENV["BEAKER_ABS_VERSION"] || "~> 0.2"
      #   nokogiri comes along for the ride but needs some restriction too
      if Gem::Version.new(RUBY_VERSION).between?(Gem::Version.new("2.1.6"),
                                                 Gem::Version.new("2.2.4"))
        @beaker_version   = ENV["BEAKER_VERSION"] || "<  3.9.0"
        @nokogiri_version = "<  1.7.0"
      elsif Gem::Version.new(RUBY_VERSION).between?(Gem::Version.new("2.0.0"),
                                                    Gem::Version.new("2.1.5"))
        @beaker_version   = ENV["BEAKER_VERSION"] || "<  3.1.0"
        @nokogiri_version = "<  1.7.0"
      else
        @beaker_version   = ENV["BEAKER_VERSION"] || "~> 3.0"
        @nokogiri_version = "~> 1" # any
      end
    end

    def location_of_interp(place, fake_version = nil)
      if place =~ /^(git:[^#]*)#(.*)/
        [fake_version, { git: Regexp.last_match[1],
                         branch: Regexp.last_match[2], :require => false }].compact
      elsif place =~ %r{^file://(.*)}
        "'>= 0', path: '#{File.expand_path(Regexp.last_match[1])}', :require => false"
      else
        "'#{place}', { :require => false }"
      end
    end

  end

  # string for use as parameter to the #gem method
  # @return [String] string for use as parameter to the #gem method
  #   forms file or git urls, typically from user env_vars
  # @param place [String] location string from an env_var
  # @param fake_version [String] uh... a git sha?
  # @api public
  # @example
  #   gem "beaker", GemOf.location_of(ENV["BEAKER_VERSION"] || "~> 1")
  def location_of(place, fake_version = nil)
    if place =~ /^(git:[^#]*)#(.*)/
      [fake_version, { git: Regexp.last_match[1],
                       branch: Regexp.last_match[2], :require => false }].compact
    elsif place =~ %r{^file:\/\/(.*)}
      [">= 0", { path: File.expand_path(Regexp.last_match[1]), :require => false }]
    else
      [place, { :require => false }]
    end
  end
  alias            location_for   location_of # reverse compat
  module_function :location_for, :location_of
end
