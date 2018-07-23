require "rubygems" # for Gem Versioning methods

# Namespace for Gem methods
module GemOf
  # produce a list of gems for use in a gems Gemfile
  # @return [String] a string of Gemfile dependencies for a Gemfile to eval
  # @example eval this in your Gemfile in its binding
  #   eval(GemOf.gems, binding)
  # @api public
  class Gems
    # rubocop:disable Metrics/MethodLength
    def initialize
      set_gem_versions

      @gem_code = <<-HEREDOC
      source "https://rubygems.org"
      # place all development, system_test, etc dependencies here

      # lint/unit tests
      gem "rake"
      # ensure downstream projects get gem_of for rake tasks
      gem "gem_of",     #{GemOf.location_of(@gemof_version)}
      gem "rototiller", "~> 1.0"
      gem "rspec",      "~> 3.4.0"
      gem "rubocop",    "~> 0.49.1" # used in tests. pinned
      gem "simplecov",  "~> 0.14.0" # used in tests
      gem "yardstick",  "~> 0.9.0"  # used in tests
      gem "markdown",   "~> 0"
      gem "flay",       "~> 2.10.0" # used in tests
      gem "flog",       "~> 4.6.0"  # used in tests
      gem "roodi",      "~> 5.0.0"  # used in tests
      gem "reek",       "#{@reek_version}"
      gem "coveralls",  require: false # used in tests

      group :system_tests do
        gem "beaker",         #{GemOf.location_of(@beaker_version)}
        gem "beaker-hostgenerator"
        gem "beaker-abs",     #{GemOf.location_of(@beaker_abs_version)}
        gem "nokogiri",       "#{@nokogiri_version}"
        gem "public_suffix",  "#{@public_suffix_version}"
        gem "jwt",            "#{@jwt_version}"
        gem "activesupport", "#{@activesupport_version}"
        gem "fog-openstack", "#{@fog_openstack_version}"
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
      # rubycritic has trouble in older rubys because of transitive deps
      unless Gem::Version.new(RUBY_VERSION).between?(Gem::Version.new("2.0.0"),
                                                     Gem::Version.new("2.1.5"))
        @gem_code += <<-HEREDOC
          gem "rubycritic", "#{@rubycritic_version}"
        HEREDOC
      end
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

    # rubocop:disable Metrics/AbcSize
    # Set instance params for the various gem versions we need based upon ruby
    #   should really only be used in above, will change, over time
    # @api private
    def set_gem_versions
      # restrict gems to enable ruby versions

      @public_suffix_version = "< 500" # any
      @activesupport_version = "< 500" # any
      @nokogiri_version      = "< 500" # any
      @jwt_version           = "< 500" # any
      @fog_openstack_version = "< 500" # any
      @reek_version          = "< 500" # any
      @rubycritic_version    = "< 500" # any
      @gemof_version         = ENV["GEMOF_VERSION"] || "< 500" # any
      @beaker_version        = ENV["BEAKER_VERSION"] || "< 500" # any
      @beaker_abs_version    = ENV["BEAKER_ABS_VERSION"] || "< 500" # any
      #   nokogiri comes along for the ride but needs some restriction too
      if Gem::Version.new(RUBY_VERSION).between?(Gem::Version.new("2.0.0"),
                                                 Gem::Version.new("2.1.5"))
        @beaker_version   = ENV["BEAKER_VERSION"] || "<  3.1.0"
        @nokogiri_version = "<  1.7.0"
        @jwt_version      = "<  2.0.0"
        @activesupport_version = "<  5.0.0"
        @fog_openstack_version = "<  0.1.23"
        @reek_version          = "<  4.0.0"
        @rubycritic_version    = "<  3.0.0"
      elsif Gem::Version.new(RUBY_VERSION).between?(Gem::Version.new("2.1.6"),
                                                    Gem::Version.new("2.2.4"))
        @beaker_version   = ENV["BEAKER_VERSION"] || "<  3.9.0"
        @nokogiri_version = "<  1.7.0"
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
  #   FIXME: git is probably broken here for interpolations
  #     make this into a class, override to_s so an instance will be properly
  #     stringified (the array in the git stuff below does not get properly
  #     stringified when interpolated, for instance
  def location_of(place, fake_version = nil)
    if place =~ /^(git:[^#]*)#(.*)/
      [fake_version, { git: Regexp.last_match[1],
                       branch: Regexp.last_match[2], require: false }].compact
    elsif place =~ %r{^file://(.*)}
      "'>= 0', path: '#{File.expand_path(Regexp.last_match[1])}', " \
        ":require => false"
    else
      "'#{place}', { :require => false }"
    end
  end
  alias            location_for   location_of # reverse compat
  module_function :location_for, :location_of
end
