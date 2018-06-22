require "spec_helper"
require "./lib/gem_of/rake_tasks"
require "rake"

describe GemOf::RakeTasks do
end

describe GemOf::GemTasks do
  it "has the bundler packaged gem tasks" do
    described_class.new
    expect { Rake.application.invoke_task "gem:clean" }.to_not raise_error
  end
end

describe GemOf::YardStickTasks do
  it "has a verify yardstick task with non-exact matching" do
    described_class.new
    expect { Rake.application.invoke_task "docs:verify" }
      .to output(/(overage: \d+\.\d+% \(threshold: \d+|least \d+% was \d+)/)
      .to_stdout
  end
end

describe GemOf::DocsTasks do
  let(:docs_tasks) { described_class.new }
  it "#arch_diagram should be private" do
    expect { docs_tasks.arch_diagram }.to raise_error(NoMethodError)
  end
  it "#exe_exists? should be private" do
    expect { docs_tasks.exe_exists? }.to raise_error(NoMethodError)
  end
  # FIXME: sloooow, find a better way, move to integration specs, or both
  it "creates an arch diagram" do
    # use from_any_proc here because the stdout comes from a subshell (rake)
    # FIXME just call arch_diagram method w/ __send and don't bother with rake
    expect { Rake.application.invoke_task "docs:yard" }
      .to output.to_stdout_from_any_process
    expect { Rake.application.invoke_task "docs:arch" }
      .to output(%r{(class diagram|have dot\/graphviz)}).to_stdout
  end
end

# rubocop:disable Metrics/BlockLength
describe GemOf::LintTasks do
  let(:lint_tasks) { described_class.new }
  it "#diff_length should be private" do
    expect { lint_tasks.diff_length }.to raise_error(NoMethodError)
  end
  it "lint:diff_length should pass when under the threshold" do
    allow(lint_tasks).to receive(:diff_length).and_return(14)
    expect { lint_tasks.send(:log_diff_length_and_exit) }
      .to output(/diff length \(\d+\) is less/).to_stdout
  end
  it "lint:diff_length should fail when over the threshold" do
    allow(lint_tasks).to receive(:diff_length).and_return(1000)
    begin
      expect { lint_tasks.send(:log_diff_length_and_exit) }
        .to output(/\[E\]: diff length \(\d+\) is more/).to_stderr
      lint_tasks.send(:log_diff_length_and_exit)
    # rubocop:disable Lint/HandleExceptions
    rescue SystemExit
    end
  end
  it "lint:diff_length should exit when over the threshold" do
    allow(lint_tasks).to receive(:diff_length).and_return(1000)
    expect { lint_tasks.send(:log_diff_length_and_exit) }
      .to raise_exception(SystemExit)
  end
  it "lint:diff_length should exit with diffnum when over the threshold" do
    allow(lint_tasks).to receive(:diff_length).and_return(1000)
    begin
      lint_tasks.send(:log_diff_length_and_exit)
    rescue SystemExit => e
      expect(e.status).to eq(1000)
    end
  end
end

describe GemOf::TestTasks do
  it "has the rspec packaged tasks" do
    described_class.new
    expect { Rake.application.invoke_task "test:check_spec" }
      .to output(/overridden from system/).to_stdout
  end
end
