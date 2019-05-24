describe Contract do

  before :all do
    @private_key = PrivateKey.new 2048
  end

  it "creates contract with creator address" do
    c = Contract.create @private_key
    c.get_creator.get_all_addresses.should == [@private_key.long_address.to_s]
    c.seal()
    c.check() and c.trace_errors()
    c.should be_ok
    c.packed
    c.hash_id.should_not be_nil

    c1 = Contract.from_packed(c.packed)
    c1.hash_id.should == c.hash_id
    c1.should == c
    c1.expires_at.should > (Time.now + 120)

    c1.hash_id.should_not be_nil
    c1.origin.should == c1.hash_id
    c1.parent.should == nil
  end

  it "provides definition and id" do
    c = Contract.create @private_key
    c.definition[:name] = "test name"
    c.definition[:description] = "test description"
    c.seal()
    c.check() and c.trace_errors()
    c.should be_ok

    c1 = Contract.from_packed(c.packed)
    c1.hash_id.should == c.hash_id
    c1.definition[:name].should == "test name"
    c1.definition[:description].should == "test description"

    id1 = c1.hash_id
    id2 = HashId.from_digest(c1.hash_id.bytes)
    id1.should == id2
    id1.bytes.should == id2.bytes
    id1.to_s.should == id2.to_s

    id2 = HashId.from_string(c1.hash_id.to_s)
    id1.should == id2
    id1.bytes.should == id2.bytes
    id1.to_s.should == id2.to_s
  end

  it "changes owner" do
    c = Contract.create @private_key
    other = PrivateKey.new 2048
    c.can_perform_role(:owner, other).should be_falsey
    c.can_perform_role(:owner, @private_key).should be_truthy
    c.owner = other.short_address
    c.can_perform_role(:owner, other).should be_truthy
    c.can_perform_role(:owner, @private_key).should be_falsey
    c.seal
    c.check.should be_truthy
  end

  include TestKeys

  it "splits to a new owner without his signature" do
    owner_b = test_keys[1]

    r0 = create_coin 10000, issuer_key: @private_key
    r0.check().should be_truthy
    r1a = r0.createRevision(@private_key)
    r1a.amount -= 42
    r1b = r1a.split(1)[0]
    r1b.owner = owner_b.public_key
    r1b.amount = 42
    r1a.seal()
    r1a.check()
    r1a.trace_errors
    r1a.is_ok.should be_truthy

    # lets perform the full check of the pack
    tp = TransactionPack.unpack(r1a.packed)
    c = tp.getContract
    if !c.check()
      c.trace_errors
      fail("unpacked transaction is not valid")
    end

    owner_c = test_keys[2]

    r2a = r1b.createRevisionWithAddress([owner_b.short_address])
    r2a.should_not be_nil

    r2b = r2a.split(1)[0]

    r2a.amount -= 4
    r2b.amount = 4
    r2b.owner = owner_c.short_address

    r2a.seal()

    r2a.addSignatureToSeal(owner_b)

    r2a.check()
    r2a.trace_errors
    r2a.should be_ok
  end

  it "splits with late signature" do
    r0 = create_coin 10000, issuer_key: @private_key
    r0.check().should be_truthy

    payer = @private_key
    payee = test_keys[1].public_key

    r1a = r0.createRevision()
    r1a.amount -= 42
    # r1a owner is not changed

    r1b = r1a.split(1)[0]
    r1b.amount = 42
    r1b.owner = payee.short_address

    # make it binary
    r1a.seal()

    # at this point we get the owner key, so we add signature to sealed binary:
    # (this is Java API method, direct call)
    r1a.addSignatureToSeal(payer)

    r1a.check()
    r1a.trace_errors
    r1a.is_ok.should be_truthy

    # lets perform the full check of the pack
    tp = TransactionPack.unpack(r1a.packed)
    c = tp.getContract
    if !c.check()
      c.trace_errors
      fail("unpacked transaction is not valid")
    end
  end

  it "big in invoke_static should be fixed" do
    # pending "UMI invoke_static bug"
    token = Service.umi.invoke_static "ContractsService", "createTokenContract",
                                      Set.new([@private_key]), Set.new([@private_key.public_key]),
                                      BigDecimal(100000)
    token.should_not be_nil
  end

  it "has proper state and transactional" do
    c = Contract.create(@private_key)
    c = Contract.from_packed(c.seal)
    c.state.should be_instance_of(Binder)
    c = Contract.from_packed(c.packed)
    c.state.should be_instance_of(Binder)
    c.transactional.should be_instance_of(Binder)
  end

  it "should have properly cacheable hashId" do
    c = Contract.create(@private_key)
    c.seal()
    id1 = c.hash_id
    id2 = HashId.from_string(c.hash_id.to_s)
    id1.should == id2
    hash = {id1 => 17}
    hash[id2].should == 17
  end

  it "should easily compare HashId" do
    c = Contract.create(@private_key)
    c.seal()
    id1 = c.hash_id
    id2 = HashId.from_string(c.hash_id.to_s)

    id1.should == id2
    id1.should == id2.to_s
    id1.should == id2.bytes
    id2.bytes.should == id1
    id2.to_s.should == id1
  end

  def create_coin(value, issuer_key:, owner: nil)
    currency = "token_test"
    owner ||= issuer_key.public_key

    c = Contract.create issuer_key, expires_at: Time.now + 3600 * 24 * 90
    d = c.definition
    s = c.state
    d[:name] = "Ultra #{currency}"
    d[:original_currency] = currency
    d[:currency] = currency
    d[:short_currency] = currency
    d[:description] = "This is a test asset for universa gem"
    c.owner = owner if owner

    amount = value.to_s
    amount.force_encoding 'utf-8'
    s[:amount] = amount

    # tricky part: mintable splitjoin
    c.add_permission SplitJoinPermission.new(
        c.owner.link_as("@owner"),
        Binder.of(
            {
                field_name: 'amount',
                min_value: "0.000000000000000001",
                min_unit: "0.000000000000000001",
                join_match_fields: [
                    "definition.data.currency",
                    "definition.data.original_currency",
                    # and issued by the same issuer
                    "definition.issuer"
                ]
            }
        )
    )
    c.seal()
    c
  end


end

class TestInit
  def initialize *args
    pp args
  end
end

class TestInit2 < TestInit
  def initialize *args
    pp args
    super
  end
end