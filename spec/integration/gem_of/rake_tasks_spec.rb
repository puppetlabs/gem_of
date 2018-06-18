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

describe GemOf::LintTasks do
  let(:lint_tasks) { described_class.new }
  it "#diff_length should be private" do
    expect { lint_tasks.diff_length }.to raise_error(NoMethodError)
  end
  # FIXME: move the two commands to their own methods, stub them out so we can
  #   create failing/succeeding tests
  it "outputs some valid diff length" do
    expect { Rake.application.invoke_task "lint:diff_length" }
      .to output(/diff length \(\d+\) is/).to_stdout
  end
end

describe GemOf::TestTasks do
  it "has the rspec packaged tasks" do
    described_class.new
    expect { Rake.application.invoke_task "test:check_spec" }
      .to output(/overridden from system/).to_stdout
  end
end

# module functions
describe GemOf do
  it "module function #location_of, #location_for should be aliases (equal)" do
    expect(described_class.method(:location_of) ==
            described_class.method(:location_for))
  end
  it "module function #location_of should return unmodified if not git path" do
    expect(described_class.location_of("something random"))
      .to eq ["something random", { require: false }]
  end
  it "module function #location_of should return git repo and branch" do
    url = "git://git.com/puppetlabs/gem_of#somesha"
    expect(described_class.location_of(url)[0][:git])
      .to eq "git://git.com/puppetlabs/gem_of"
    expect(described_class.location_of(url)[0][:branch])
      .to eq "somesha"
  end
  it "module function #location_of should return local file path: elements" do
    expect(described_class.location_of("file://../somethingelse")[0])
      .to eq ">= 0"
    expect(described_class.location_of("file://../somethingelse")[1][:path])
      .to match("somethingelse")
  end
end
