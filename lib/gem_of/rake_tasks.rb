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
        desc "Measure YARD coverage. see yardstick/report.txt for output"
        require "yardstick/rake/measurement"
        Yardstick::Rake::Measurement.new(:measure) do |measurement|
          measurement.output = "yardstick/report.txt"
        end

        desc "Verify YARD coverage"
        require "yardstick/rake/verify"
        config = { "require_exact_threshold" => false }
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
          sh "rm -rf #{YARD_DIR}"
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
      # this won't work all the time, and when it doesn't,
      #   it still says we created a class diagram
      # FIXME: use Rake.application.original_dir
      # Dir.chdir(File.expand_path(File.dirname(__FILE__)))
      graph_processor = "dot"
      if exe_exists?(graph_processor)
        FileUtils.mkdir_p(DOCS_DIR)
        if system("yard graph --full | #{graph_processor} -Tpng " \
            "-o #{DOCS_DIR}/arch_graph.png")
          puts "we made you a class diagram: #{DOCS_DIR}/arch_graph.png"
        end
      else
        puts "ERROR: you don't have dot/graphviz; punting"
      end
      Dir.chdir(original_dir)
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
          diff_length? exit diff_length: exit
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
    def diff_length
      max_length = 150
      target_branch = ENV["DISTELLI_RELBRANCH"] || "master"
      diff_cmd = "git diff --numstat #{target_branch}"
      sum_cmd  = "awk '{s+=$1} END {print s}'"
      diff_len = `#{diff_cmd} | #{sum_cmd}`.to_i
      if diff_len < max_length
        puts "diff length (#{diff_len}) is less than #{max_length} LoC"
        return
      else
        puts "diff length (#{diff_len}) is more than #{max_length} LoC"
        return diff_len
      end
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
            t.rspec_opts = ["--color"]
            t.pattern = ENV["SPEC_PATTERN"]
          end
          # if rspec isn't available, we can still use this Rakefile
          # rubocop:disable Lint/HandleExceptions
        rescue LoadError
        end

        task spec: [:check_spec]

        desc "" # empty description so it doesn't show up in rake -T
        rototiller_task :check_spec do |t|
          t.add_env(name: "SPEC_PATTERN", default: "spec/",
                    message: "The pattern RSpec will use to find tests")
        end
      end
    end
  end
end