describe SecureLoanHelper do

  before :all do
    # Service.log_umi

    @lender_key = PrivateKey.new 2048
    @borrower_key = PrivateKey.new 2048
    @lender_address = @lender_key.short_address
    @borrower_address = @borrower_key.short_address
  end

  it "creates contract with creator address" do
    asset = Contract.create @lender_key
    asset.seal
    pledge = Contract.create @borrower_key
    pledge.seal

    lend, borrowed_asset = SecureLoanHelper.create lender_address: @lender_address,
                                                   borrower_address: @borrower_address,
                                                   loan_contract: asset,
                                                   duration: Duration.of_days(15),
                                                   collateral: pledge,
                                                   mintable: false,
                                                   repayment_amount: BigDecimal(100),
                                                   repayment_origin: asset.origin,
                                                   data: { foo: 'bar' }


    lend.should_not be_nil
    lend.definition.foo.should == 'bar'
    borrowed_asset.should_not be_nil
    borrowed_asset.owner.isAllowedForKeys(Set.new([@borrower_key.public_key])).should be_truthy
  end

end