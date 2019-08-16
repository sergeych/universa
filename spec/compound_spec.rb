require 'spec_helper'

describe Compound do

  include TestKeys

  before :all do
    Service.log_umi

    @key = test_keys[0]
    @key2 = test_keys[1]

  end

  it "creates contract with creator address" do
    contract = Contract.new(@key)
    contract.state.test = "123"
    contract.setIssuerKeys(@key2.long_address)
    contract.seal()
    # contract.check.should be_falsey

    compound = Compound.new()
    compound.addContract('c1', contract, {foo: 'bar'})
    cc = compound.getCompoundContract()
    cc.seal()
    cc.addSignatureToSeal(@key2)
    cc.addSignatureToSeal(@key)
    cc.check()
    cc.trace_errors
    cc.check().should be_truthy
  end

end