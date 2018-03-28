describe GemOf::Gems do
  it "set_gem_versions should be private" do
    expect { described_class.new.set_gem_versions }
      .to raise_error(NoMethodError)
  end
  it "should be a string" do
    expect(described_class.new.to_s).to be_instance_of(String)
    expect(described_class.new.to_str).to be_instance_of(String)
  end
end

describe GemOf do
  it "module function #location_of, #location_for should be aliases (equal)" do
    expect(described_class.method(:location_of) ==
            described_class.method(:location_for))
  end
  it "module function #location_of should return unmodified if not git path" do
    expect(described_class.location_of("something random"))
      .to eq ["something random"]
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
