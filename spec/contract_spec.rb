describe Contract do

  before :all do
    @private_key = PrivateKey.new 2048
  end

  it "assigns references" do
    transfer = Contract.new()
    can_play_parent_owner_ref = Reference.new(transfer)
    can_play_parent_owner_ref.type = Universa::Reference::TYPE_TRANSACTIONAL
    can_play_parent_owner_ref.name = "canplayparentowner"
    can_play_parent_owner_ref.setConditions(Universa::Binder.of("all_of", ["this can_perform refParent.owner"]))

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

  it "properly serializes data in definition and state" do
    c = Contract.create @private_key
    d = Time.now
    c.definition[:date1] = d
    c.definition[:str1] = "foo"
    c.state[:date2] = d
    c.state[:str2] = "bar"
    c.seal
    c1 = Contract.from_packed(c.packed)
    c1.definition.date1.should be_a(Time)
    c1.state.date2.should be_a(Time)
  end

  it "unpacks new style contracts" do
    packed = Base64.decode64 <<-END
JyNkYXRhxC0PH0Njb250cmFjdC9LYXBpX2xldmVsIFNkZWZpbml0aW9uLzNp
c3N1ZXJHG3Jhd8QMAiYAHAEAAcQAAd/eJFo0WE797GSZ4Z3BLaLsIDV2osfu
HjKp/9q4D3hUkED+ulp7x2Vtwd/VO2C886YaGVA2doef342vikJ7ypRmDqcK
48IH53vqpgXpeD4IcacTv9q+bdzN8wAzmeKjINZ5dgsd15lnrPbjvB9K9x84
M9QN1EZmpg6/F2zmzrIYvK/IK76o5/FD/hT4x58ThxDt6sOad+7mA50Oz9oM
jLsbu42DpnvVz3yYVty/62gorp6HLS24axcRWJkokHU24rSRUa3o2dXfVxki
c4YjvWFWNN8zHiyW4tbjfN4Dzm7JcYjyRVBv4CEptbXg7Sm8zRsBQ265e8XR
eEvzeUwUmnXEAAH4AQR87AU8AuaysXeSbBgeE0p5MTGkEn6bF4LcKD41r0y/
Cvv0Wc//pqLt+a3Nbpsb0tO6gpxW26VcprQLTVqZVsyn+MESsVEPY8UmyUET
3mK61SmEYZV94ZbuyR1ef7wvPpA1xf9+c8derLocc8VzwyyLU7/52S1x91/z
tsDF5qYSPMnOtwnYkHlN9g5XiyHk9BatMxL9f92nfcNW4xBW+6lU/Ta0x+Yo
Y4EV5NWyYQEpNrFFZQuKnPTVyV14jrIhHT5Pij5I1hGDGyV6oqfq4gUTEGtE
WLdMi36HZ3LPbVSbYWwsErZo+49vrOQqlfyJQKFIrJH14Jo4L31RjNXHS3B1
YmxpY0tleVdNxAkCHggcAQABxAAC2OAXAj2gIrWABU/7cx2G9Tct1XWFMSA5
A5L2n6xcx3X8JuFLjIHk5Mu58CxPSBjJ0oISfcY1Aoaf19eIdZyfWkHTwZBA
rDOn41xmYXcKkDO6viELiOtG7cLRuHza4mJXSvsiGuXMyzex5NQOngEwYbfR
4nuAvvDhCguvZWVesq6wUtp17SOwSpZQjoLe8KyEdhUe9PVHuLdHA0nZKC43
Og5D1ikcjv5Qjo4fzLLPX5sZP1mTgYxPrXzxPAdJIvnKbMLoy/Hxu/qYANos
WQHHB+wjuq0Go5xaVMMJshqWTsNvTrvSgbA7tLC0Ru0JzIQHN3WwtUQ0XjX/
lpVU4Gk65WU8n0b+stMhY6YShTtmJXI8CwABJXodg5CRBL2i+c83ru3ugynj
xnpWbxDPlerNU+uktsT1cjaob9TKkXirIXPYhNDFDyrFic+606Ec38fhXhyG
/UBeNp7ptg7L93Ig8zUhffqe6Q+04zevRvIwW4RXXaUHVdWiDqFJllpn7pQe
31yERRwu3HwOG9DEB65QsdCcuCWaXKh3d6746lf3XUPkOmoRrNPVFn1hk15O
Rgy3Gv2J7stHZqJswGvt1fBCp0xHWphnMhopf145TBm+5nJqAJ29F3yYrv2G
MtkTvJkIrd8Qdw3W4+UGBtUvWgeMFnW+R2vroDB8Vgk128WDafMLbsMABGQ4
ZTAxNzAyM2RhMDIyYjU4MDA1NGZmYjczMWQ4NmY1MzcyZGQ1NzU4NTMxMjAz
OTAzOTJmNjlmYWM1Y2M3NzVmYzI2ZTE0YjhjODFlNGU0Y2JiOWYwMmM0ZjQ4
MThjOWQyODIxMjdkYzYzNTAyODY5ZmQ3ZDc4ODc1OWM5ZjVhNDFkM2MxOTA0
MGFjMzNhN2UzNWM2NjYxNzcwYTkwMzNiYWJlMjEwYjg4ZWI0NmVkYzJkMWI4
N2NkYWUyNjI1NzRhZmIyMjFhZTVjY2NiMzdiMWU0ZDQwZTllMDEzMDYxYjdk
MWUyN2I4MGJlZjBlMTBhMGJhZjY1NjU1ZWIyYWViMDUyZGE3NWVkMjNiMDRh
OTY1MDhlODJkZWYwYWM4NDc2MTUxZWY0ZjU0N2I4Yjc0NzAzNDlkOTI4MmUz
NzNhMGU0M2Q2MjkxYzhlZmU1MDhlOGUxZmNjYjJjZjVmOWIxOTNmNTk5Mzgx
OGM0ZmFkN2NmMTNjMDc0OTIyZjljYTZjYzJlOGNiZjFmMWJiZmE5ODAwZGEy
YzU5MDFjNzA3ZWMyM2JhYWQwNmEzOWM1YTU0YzMwOWIyMWE5NjRlYzM2ZjRl
YmJkMjgxYjAzYmI0YjBiNDQ2ZWQwOWNjODQwNzM3NzViMGI1NDQzNDVlMzVm
Zjk2OTU1NGUwNjkzYWU1NjUzYzlmNDZmZWIyZDMyMTYzYTYxMjg1M2I2NjI1
NzIzYzBiMDAwMTI1N2ExZDgzOTA5MTA0YmRhMmY5Y2YzN2FlZWRlZTgzMjll
M2M2N2E1NjZmMTBjZjk1ZWFjZDUzZWJhNGI2YzRmNTcyMzZhODZmZDRjYTkx
NzhhYjIxNzNkODg0ZDBjNTBmMmFjNTg5Y2ZiYWQzYTExY2RmYzdlMTVlMWM4
NmZkNDA1ZTM2OWVlOWI2MGVjYmY3NzIyMGYzMzUyMTdkZmE5ZWU5MGZiNGUz
MzdhZjQ2ZjIzMDViODQ1NzVkYTUwNzU1ZDVhMjBlYTE0OTk2NWE2N2VlOTQx
ZWRmNWM4NDQ1MWMyZWRjN2MwZTFiZDBjNDA3YWU1MGIxZDA5Y2I4MjU5YTVj
YTg3Nzc3YWVmOGVhNTdmNzVkNDNlNDNhNmExMWFjZDNkNTE2N2Q2MTkzNWU0
ZTQ2MGNiNzFhZmQ4OWVlY2I0NzY2YTI2Y2MwNmJlZGQ1ZjA0MmE3NGM0NzVh
OTg2NzMyMWEyOTdmNWUzOTRjMTliZWU2NzI2YTAwOWRiZDE3N2M5OGFlZmQ4
NjMyZDkxM2JjOTkwOGFkZGYxMDc3MGRkNmUzZTUwNjA2ZDUyZjVhMDc4YzE2
NzViZTQ3NmJlYmEwMzA3YzU2MDkzNWRiYzU4MzY5ZjMLZSsxMDAwMVtiaXRT
dHJlbmd0aMAAEGNfZmluZ2VycHJpbnS8IQfaM0JFxxk7/kXz70jlvkd4PZOI
CwxIRb+gwMTCzTp73XNzaG9ydEFkZHJlc3M1OLszMjZKQ0ZYdDRBSEFFWG12
VEtuNlR6YnRlYm1zNHlwd3JDWTJITGRScm9CQllXeDc3YUxNa2xvbmdBZGRy
ZXNzNTi7SGJXYWpTTVlzWGJtZEhBWDY4amhGakJ6eVV4Snp1ZFFMcVBpWndQ
dDVrUWdQTTJEUmF5UENHWVlncWRZeTdjMzk3NWt2U1BUV2NzaG9ydEFkZHJl
c3MXQ3VhZGRyZXNzvCUgj+UgnT6eTj46bBIu7CKP4RxQKGfax1WC/s+IFOpn
CLciug92M19fdHlwZVNLZXlBZGRyZXNzW2xvbmdBZGRyZXNzF70bvDUgkqDX
BfekYCxJlN6iGNvhVX8hTO6S9N/fxvGuvyuT0YZ77YhtSJWrYdNZqCs3OR5l
rt47Mb0dvR47X3BhY2tlZG11fYWNC3DDAAJkZmRlMjQ1YTM0NTg0ZWZkZWM2
NDk5ZTE5ZGMxMmRhMmVjMjAzNTc2YTJjN2VlMWUzMmE5ZmZkYWI4MGY3ODU0
OTA0MGZlYmE1YTdiYzc2NTZkYzFkZmQ1M2I2MGJjZjNhNjFhMTk1MDM2NzY4
NzlmZGY4ZGFmOGE0MjdiY2E5NDY2MGVhNzBhZTNjMjA3ZTc3YmVhYTYwNWU5
NzgzZTA4NzFhNzEzYmZkYWJlNmRkY2NkZjMwMDMzOTllMmEzMjBkNjc5NzYw
YjFkZDc5OTY3YWNmNmUzYmMxZjRhZjcxZjM4MzNkNDBkZDQ0NjY2YTYwZWJm
MTc2Y2U2Y2ViMjE4YmNhZmM4MmJiZWE4ZTdmMTQzZmUxNGY4Yzc5ZjEzODcx
MGVkZWFjMzlhNzdlZWU2MDM5ZDBlY2ZkYTBjOGNiYjFiYmI4ZDgzYTY3YmQ1
Y2Y3Yzk4NTZkY2JmZWI2ODI4YWU5ZTg3MmQyZGI4NmIxNzExNTg5OTI4OTA3
NTM2ZTJiNDkxNTFhZGU4ZDlkNWRmNTcxOTIyNzM4NjIzYmQ2MTU2MzRkZjMz
MWUyYzk2ZTJkNmUzN2NkZTAzY2U2ZWM5NzE4OGYyNDU1MDZmZTAyMTI5YjVi
NWUwZWQyOWJjY2QxYjAxNDM2ZWI5N2JjNWQxNzg0YmYzNzk0YzE0OWE3NQtx
wwACZjgwMTA0N2NlYzA1M2MwMmU2YjJiMTc3OTI2YzE4MWUxMzRhNzkzMTMx
YTQxMjdlOWIxNzgyZGMyODNlMzVhZjRjYmYwYWZiZjQ1OWNmZmZhNmEyZWRm
OWFkY2Q2ZTliMWJkMmQzYmE4MjljNTZkYmE1NWNhNmI0MGI0ZDVhOTk1NmNj
YTdmOGMxMTJiMTUxMGY2M2M1MjZjOTQxMTNkZTYyYmFkNTI5ODQ2MTk1N2Rl
MTk2ZWVjOTFkNWU3ZmJjMmYzZTkwMzVjNWZmN2U3M2M3NWVhY2JhMWM3M2M1
NzNjMzJjOGI1M2JmZjlkOTJkNzFmNzVmZjNiNmMwYzVlNmE2MTIzY2M5Y2Vi
NzA5ZDg5MDc5NGRmNjBlNTc4YjIxZTRmNDE2YWQzMzEyZmQ3ZmRkYTc3ZGMz
NTZlMzEwNTZmYmE5NTRmZDM2YjRjN2U2Mjg2MzgxMTVlNGQ1YjI2MTAxMjkz
NmIxNDU2NTBiOGE5Y2Y0ZDVjOTVkNzg4ZWIyMjExZDNlNGY4YTNlNDhkNjEx
ODMxYjI1N2FhMmE3ZWFlMjA1MTMxMDZiNDQ1OGI3NGM4YjdlODc2NzcyY2Y2
ZDU0OWI2MTZjMmMxMmI2NjhmYjhmNmZhY2U0MmE5NWZjODk0MGExNDhhYzkx
ZjVlMDlhMzgyZjdkNTE4Y2Q1YzeVwAAQnaVbcGVybWlzc2lvbnMPMzZPWWkw
MB8jbmFtZTNyZXZva2Ujcm9sZR+9KztAcmV2b2tlW3RhcmdldF9uYW1lK293
bmVyvR1DUm9sZUxpbmu9HYNSZXZva2VQZXJtaXNzaW9uU2NyZWF0ZWRfYXR5
XD8eBYYjZGF0YQ+9KyN0ZXN0U3JlZmVyZW5jZXMGK3N0YXRlX700eVw/HgWG
U2V4cGlyZXNfYXR5XGU7UIa9MR+9K70xvTA9vR29MlNjcmVhdGVkX2J5H70r
O2NyZWF0b3K9MD29Hb0yvTUHQ3JldmlzaW9uCCtyb2xlcwczcGFyZW50BTNv
cmlnaW4FS2JyYW5jaF9pZAW9OAZrdHJhbnNhY3Rpb25hbAW9HYNVbml2ZXJz
YUNvbnRyYWN0G25ldwZDcmV2b2tpbmcGU3NpZ25hdHVyZXMGI3R5cGVTdW5p
Y2Fwc3VsZTt2ZXJzaW9uIA==
    END

    # require 'universa/dump'
    # c = Contract.from_packed packed
    # puts Universa.dump_bytes packed, 8
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

