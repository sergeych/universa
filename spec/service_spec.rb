describe Service do

  # it "should have single instance" do
  #   Service.instance.should_not be_nil
  #   Service.configure {|cfg|
  #     cfg.path.should be_nil
  #   }
  #   Service.umi.should be_instance_of(UMI)
  # end

  context "when created" do

    it "create and restore proxy objects" do
      key = PrivateKey.new 2048
      contract = Contract.new(key)
      k1 = contract.keys_to_sign_with[0]
      k2 = contract.keys_to_sign_with[0]
      key.should == k1
      k1.should == k2

      # These should point to the same object
      k1._remote_id.should == key._remote_id
      k1.should == k2
      key.should == k1

      # and restored object should be the same, not just equal: no dup should occur
      key.__id__.should == k1.__id__

      contract.seal()
      contract.check().should be_truthy
    end

    it "compare different by considered equal objects" do
      key1 = PrivateKey.new 2048
      key2 = PrivateKey.new key1.pack
      key1.__id__.should_not == key2.__id__
      key1.should == key2
      key1.short_address.should == key2.short_address
      key1.long_address.should == key2.long_address
      key1.short_address.to_s.should == key2.short_address.to_s
      # key1.short_address.should
    end

  end


end