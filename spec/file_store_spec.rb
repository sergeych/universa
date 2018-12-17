include Universa

include Universa::FSStore

describe Universa::FSStore::FileStore do

  include TestKeys

  it "opens empty store" do
    cc, store = create_test_store
    store.count.should == 5
    5.times { |n|
      c = cc[n]
      store.find_by_id!(c.hash_id).contract.should == c
    }
  end

  it "opens not empty store" do
    cc, existing_store = create_test_store
    store = FileStore.new(existing_store.root)
    store.count.should == 5
    5.times { |n|
      c = cc[n]
      store.find_by_id!(c.hash_id).contract.hash_id.should == c.hash_id
    }
  end

  def create_test_store
    store = FileStore.new(Dir.mktmpdir("test_universa_gem"))
    store.root.length.should > 0
    store.count.should == 0

    cc = 5.times.map {
      c = Contract.create test_keys[0]
      c.seal()
      store << c
      c
    }
    return cc, store
  end


end
