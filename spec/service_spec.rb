describe Service do

  # it "should have single instance" do
  #   Service.instance.should_not be_nil
  #   Service.configure {|cfg|
  #     cfg.path.should be_nil
  #   }
  #   Service.umi.should be_instance_of(UMI)
  # end

  context "when created" do

    context "supports binder" do
      before :each do
        @src = {"hello" => "world", "foo" => 101}
        @binder = Service.umi.invoke_static "Binder", "of", *@src.to_a.flatten
      end

      it "provides valid interface to remote binder" do
        # This should be converted to a "binder" adapter
        @binder["hello"].should == "world"
        @binder[:foo].should == 101
        @binder.should be_instance_of(Binder)
        @binder.size.should == 2

        # It should behave like an object
        @binder.hello.should == 'world'
        @binder.foo.should == 101

        # and it sould be like ruby collection
        Set.new(@binder.keys).should == Set.new(['foo', 'hello'])
        @binder.keys.should be_instance_of(Array)
        Set.new(@binder.values).should == Set.new(['world', 101])
        @binder.values.should be_instance_of(Array)

        @binder.not_existing.should == nil
      end

      it "converts to array" do
        @binder.to_a.to_h.should == @src
      end

      it "provides map" do
        @binder.map {|x, y| [x, y]}.to_h.should == @src
      end
      it "converts to hash" do
        @binder.to_h.should == @src
      end

      it "provides each" do
        res = {}
        @binder.each {|x, y| res[x] = y}
        res.should == @src
      end

      it "provides to_binder" do
        b = { hello: 1}.to_binder
        b.should be_instance_of(Binder)
        b.to_h.should == { 'hello' => 1}
      end

      it "allow nesting objects" do
        b1 = Binder.of( "foo", "bar")
        b2 = Binder.of( "bar", b1)
        b2[:bar].should be_instance_of(Binder)
        b2[:bar].should == b1
        b3 = Binder.of "l3", b2
        b3[:l3].should be_instance_of(Binder)
        b3[:l3].should == b2
        b3[:l3][:bar].should be_instance_of(Binder)
        b3[:l3][:bar].should == b1
      end

      it "nested binder in array" do
        b1 = Binder.of( "foo", "bar")
        b2 = Binder.of( "bar", [1, b1])
        b2[:bar][1].should be_instance_of(Binder)
        b2[:bar][1].should == b1
        b3 = Binder.of("baz": [1, [2, [3, b1]]])
        b3[:baz][1][1][1].should be_instance_of(Binder)
        b3[:baz][1][1][1].should == b1
      end

      it "allow fined in hash" do
        b1 = Binder.of( "foo", "bar")
        b2 = Binder.of( "bar", { first: b1})
        b2[:bar]['first'].should be_instance_of(Binder)
        b2[:bar]['first'].should == b1
      end

      it "let binder include binder" do
        b1 = Binder.of( "foo", "bar")
        b2 = Binder.of( "bar", Binder.of("buzz": b1))
        b2[:bar]['buzz'].should be_instance_of(Binder)
        b2[:bar]['buzz'].should == b1
      end

      it "support nested binders in arguments" do
        b1 = Binder.of( "foo" => "bar", "bar" => Binder.of("foo" => "bar"))
        b1[:bar][:foo].should == 'bar'
      end

      it "initializes binder with hash" do
        a = Binder.of(foo: 'bar', bar: { buzz: 'ok'})
        a.foo.should == 'bar'
        a.bar[:buzz].should == 'ok'
      end

      it "let access Role data members" do
        r = Reference.new
        r.name.should == ""
        r.name = "foobar"
        r.name.should == "foobar"
        Reference::ALL_OF.should == 'all_of'
        Reference::ANY_OF.should == 'any_of'
        Reference::SIMPLE_CONDITION.should == 'simple_condition'
        r.type.should == Reference::TYPE_EXISTING_DEFINITION
        r.transactional_id.should be_empty
        r.origin.should be_nil
        r.matching_items.should == []
      end

    end

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

    it "has symmetric keys" do
      sk = SymmetricKey.new
      sk.size_in_bits.should == 256
      sk.size.should == 32
      sk.key.size.should == 32

      sk1 = SymmetricKey.new(sk.key)
      sk1.should == sk

      pk1 = SymmetricKey.from_password 'hello', 1000
      pk2 = SymmetricKey.from_password 'hello', 1000
      pk3 = SymmetricKey.from_password 'hello', 1001
      pk4 = SymmetricKey.from_password 'hello', 1000, "salted!"
      pk5 = SymmetricKey.from_password 'hello', 1000, "salted!"

      pk3.should_not == pk1
      pk2.should == pk1
      pk4.should_not == pk1
      pk5.should == pk4

      # sk = Service.umi.instantiate "com.icodici.crypto.SymmetricKey"
      # p sk
    end

  end


  # context "default wallet" do
  #
  #   before :all do
  #
  #     skip "create default wallet"
  #   end
  #
  #   it "has UTN balance"
  #   it "has U balance"
  #   it "has testU balance"
  #
  # end


end