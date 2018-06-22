require "spec_helper"

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

# rubocop:disable Metrics/BlockLength
describe GemOf do
  it "module function #location_of, #location_for should be aliases (equal)" do
    expect(described_class.method(:location_of) ==
            described_class.method(:location_for))
  end
  it "module function #location_of should return unmodified, \
      with `require false` if not git path" do
    expect(described_class.location_of("something random"))
      .to eq "'something random', { :require => false }"
  end
  it "module function #location_of should return git repo and branch" do
    url = "git://git.com/puppetlabs/gem_of#somesha"
    expect(described_class.location_of(url)[0][:git])
      .to eq "git://git.com/puppetlabs/gem_of"
    expect(described_class.location_of(url)[0][:branch])
      .to eq "somesha"
  end
  it "module function #location_of should return local file path: elements" do
    expect(described_class.location_of("file://../somethingelse"))
      .to match %r{'>= 0', path: '.*/somethingelse', :require => false}
  end
  context "function #location_of return can be interpolated into strings" do
    it "works with a file url" do
      expect("somestring #{described_class
        .location_of('file://../somethingelse')} andanother")
        .to match %r{somestring\s'>=\s0',\spath:\s'.*/somethingelse',\s
                     :require\s=>\sfalse\sandanother}x
    end
    it "works with a non url" do
      expect("somestring #{described_class
        .location_of('something random')} and")
        .to match(/somestring\s'something\srandom',\s
                   {\s:require\s=>\sfalse\s}\sand/x)
    end
    # FIXME: this is currently unsupported
    # rubocop:disable Layout/LeadingCommentSpace,Layout/CommentIndentation
    #it "works with a git url" do
      #url = "git://git.com/puppetlabs/gem_of#somesha"
      #expect("somestring #{described_class.location_of(url)} andanother")
        #.to match %r{somestring :git => git://git.com/puppetlabs/gem_of,
      #:branch => "somesha", :require => false andanother}
    #end
  end
end
