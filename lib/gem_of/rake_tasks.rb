require "fileutils"
require "rototiller"
require "yard"
require "rubocop/rake_task"
require "flog_task"
require "flay_task"
require "roodi_task"
require "rubycritic/rake_task"

module GemOf
  # a bunch of instances of other rake tasks
  # @example create an instance of me in your rakefile
  #   GemOf::RakeTasks.new
  # @api public
  class RakeTasks
    include Rake::DSL
    # instance a bunch of our component rake tasks
    # @api public
    def initialize
      task :default do
        sh %(rake -T)
      end
      GemTasks.new
      YardStickTasks.new
      DocsTasks.new
      LintTasks.new
      TestTasks.new
    end
  end

  # a class to hold the bundler provided "gem" tasks
  # bund of gem build, clean, install, release tasks
  class GemTasks
    # instance bundler gemtasks in namespace :gem
    # @api public
    # @example GemTasks.new
    include Rake::DSL if defined? Rake::DSL
    def initialize
      namespace :gem do
        require "bundler/gem_tasks"
      end
    end
  end

  # a class to hold the yardstick provided yarddoc tasks
  class YardStickTasks
    include Rake::DSL if defined? Rake::DSL
    # rubocop:disable Metrics/MethodLength
    # instance yardstick tasks in namespace :docs
    # @api public
    # @example YardStackTasks.new
    def initialize
      namespace :docs do
        config = { "require_exact_threshold" => false,
                   "rules" => { "Summary::Length" => { "enabled" => false },
                                "Summary::SingleLine" => { "enabled" => false },
                                "ApiTag::Presence" => { "enabled" => false },
                                "ApiTag::Inclusion" => { "enabled" => false },
                                "ApiTag::ProtectedMethod" =>
                                  { "enabled" => false },
                                "ApiTag::PrivateMethod" =>
                                  { "enabled" => false } } }
        desc "Measure YARD coverage. see yardstick/report.txt for output"
        require "yardstick/rake/measurement"
        Yardstick::Rake::Measurement.new(:measure, config) do |measurement|
          measurement.output = "yardstick/report.txt"
        end
        task measure: [:measure_message] # another way to force a dependent task
        desc "" # empty description so this doesn't show up in rake -T
        task :measure_message do
          puts "creating a report for you in yardstick/report.txt"
        end

        desc "Verify YARD coverage"
        require "yardstick/rake/verify"
        Yardstick::Rake::Verify.new(:verify, config) do |verify|
          verify.threshold = 80
        end
      end
    end
  end

  # various yarddoc docs tasks
  #   arch, clean, measure, undoc, verify, yard
  class DocsTasks
    include Rake::DSL if defined? Rake::DSL
    # location of the yarddocs produced
    YARD_DIR = "doc".freeze
    # location of the human user docs (markdown, etc)
    DOCS_DIR = "docs".freeze

    # instance yardoc tasks in namespace :docs
    # @api public
    # @example DocsTasks.new
    def initialize
      namespace :docs do
        # docs:yard task
        YARD::Rake::YardocTask.new

        desc "Clean/remove the generated YARD Documentation cache"
        task :clean do
          rakefile_path = Rake.application.original_dir
          FileUtils.rm_rf(File.join(rakefile_path, YARD_DIR))
        end

        desc "Tell me about YARD undocumented objects"
        YARD::Rake::YardocTask.new(:undoc) do |t|
          t.stats_options = ["--list-undoc"]
        end

        desc "Generate static project architecture graph. (Calls docs:yard)"
        # this calls `yard graph` so we can't use the yardoc tasks like above
        #   We could create a YARD:CLI:Graph object.
        #   But we have to send the output to the graphviz processor, etc.
        task arch: [:yard] do
          arch_diagram
        end
      end
    end

    private

    # @private
    def arch_diagram
      original_dir = Dir.pwd
      # rake can be run from any dir under here
      #   so we don't know where we are
      #   yard graph needs access to the lib file tree, and you can't specify it
      #   to yard.  so we need to chdir here.
      # FIXME: this won't work from other dirs, because bundler complains it
      #   can't find ./lib/gem_of.rb (from Gemfile)
      graph_processor = "dot"
      if exe_exists?(graph_processor)
        rakefile_path = Rake.application.original_dir
        Dir.chdir(rakefile_path)
        FileUtils.mkdir_p(DOCS_DIR)
        if system("yard graph --full | #{graph_processor} -Tpng " \
            "-o #{DOCS_DIR}/arch_graph.png")
          puts "we made you a class diagram: #{DOCS_DIR}/arch_graph.png"
        end
        Dir.chdir(original_dir)
      else
        puts "ERROR: you don't have dot/graphviz; punting"
      end
    end

    # Cross-platform exe_exists?
    # @private
    def exe_exists?(name)
      exts = ENV["PATHEXT"] ? ENV["PATHEXT"].split(";") : [""]
      ENV["PATH"].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{name}#{ext}")
          return true if File.executable?(exe) && !File.directory?(exe)
        end
      end
      false
    end
  end

  # various lint-oriented tasks
  class LintTasks
    include Rake::DSL if defined? Rake::DSL
    # instance lint takss in namespace :lint
    # @api public
    # @example LintTasks.new
    def initialize
      namespace :lint do
        desc "check number of lines of code changed. No long PRs"
        task "diff_length" do
          log_diff_length_and_exit
        end

        # this will produce 'test:rubocop','test:rubocop:auto_correct' tasks
        RuboCop::RakeTask.new do |task|
          task.options = ["--debug"]
        end

        # this will produce the 'test:flog' task
        allowed_complexity = 585 # <cough!>
        FlogTask.new :flog, allowed_complexity, %w[lib]
        # this will produce the 'test:flay' task
        allowed_repitition = 0
        FlayTask.new :flay, allowed_repitition, %w[lib]
        # this will produce the 'test:roodi' task
        RoodiTask.new
        # this will produce the 'test:rubycritic' task
        RubyCritic::RakeTask.new do |task|
          task.paths   = FileList["lib/**/*.rb"]
        end
      end
    end

    private

    # @api private
    def log_diff_length_and_exit
      max_length = 500
      diff_len = diff_length
      if diff_len < max_length
        puts "diff length (#{diff_len}) is less than #{max_length} LoC"
      else
        STDERR.puts "[E]: diff length (#{diff_len}) is more than \
                     #{max_length} LoC"
        exit diff_len
      end
    end

    # @api private
    def diff_length
      target_branch = ENV["DISTELLI_RELBRANCH"] || "master"
      diff_cmd = "git diff --numstat #{target_branch}"
      sum_cmd  = "awk '{s+=$1} END {print s}'"
      `#{diff_cmd} | #{sum_cmd}`.to_i
    end
  end

  # unit testing tasks
  class TestTasks
    include Rake::DSL if defined? Rake::DSL
    # instance unit tasks in namespace :test
    # @api public
    # @example TestTasks.new
    def initialize
      namespace :test do
        begin
          # this will produce the 'test:spec' task
          require "rspec/core/rake_task"
          desc "Run unit tests"
          RSpec::Core::RakeTask.new do |t|
            t.rspec_opts = ["--color --format documentation"]
            t.pattern = ENV["SPEC_PATTERN"]
          end
          # if rspec isn't available, we can still use this Rakefile
          # rubocop:disable Lint/HandleExceptions
        rescue LoadError
        end

        task spec: [:check_spec]

        desc "" # empty description so it doesn't show up in rake -T
        rototiller_task :check_spec do |t|
          t.add_env(name: "SPEC_PATTERN", default: "**{,/*/**}/*_spec.rb",
                    message: "The pattern RSpec will use to find tests")
        end
      end
    end
  end
end
