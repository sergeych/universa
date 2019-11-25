describe UMI do

  before :all do
    # UMI.session_log_path = "session-log.txt"
    @umi = Service.umi
  end

  it "supports protocol" do
    @umi.send(:call,"version").system.should == 'UMI'
    @umi.core_version.should =~ /^\d+\.\d+\./
  end

  it "raises correct errors" do
    expect(->{@umi.send(:call,"invoke", "Core", "getBadVersion")})
        .to raise_error(NoMethodError)
  end

  it "create many objects" do
    u = Service.umi
    10000.times.map {|n| u.instantiate('Binder')}
  end

end