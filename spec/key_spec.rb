
describe "keys" do

  UMI::session_log_path = "./umisession.log"

  before :all do
    @key = PrivateKey.new 2048
    @pub = @key.public_key
  end

  it "RSA signs" do
    test = "hello world"
    signature = @key.sign(test)
    @pub.verify(test, signature).should be_truthy
    signature[0] = (~signature[0].ord & 0xFF).chr
    @pub.verify(test, signature).should be_falsey
  end

  it "RSA signs with sha2" do
    test = "hello world"
    signature = @key.sign(test, "SHA256")
    @pub.verify(test, signature, "SHA256").should be_truthy
    signature[0] = (~signature[0].ord & 0xFF).chr
    @pub.verify(test, signature).should be_falsey
  end

  it "has strength" do
    @pub.bit_strength.should == 2048
    @key.bit_strength.should == 2048
  end

  it "RSA encrypts" do
    plaintext = "foobar buzz and all"
    ciphertext = @pub.encrypt(plaintext)
    @key.decrypt(ciphertext).should == plaintext
  end

  it "AES EtA de/encrypts" do
    plaintext = "beyond all recognition"
    key = SymmetricKey.new
    ciphertext = key.eta_encrypt(plaintext)
    key.eta_decrypt(ciphertext).should == plaintext
    expect(->{key.eta_decrypt(ciphertext+"+")}).to raise_error(Farcall::RemoteError, /HMAC/)
  end

  require 'universa/dump'
  it "produces compatibility vectors" do
    key = SymmetricKey.new
    plaintext = "false vaccine kills"
    packedKey = Boss.pack(packedKey)
    print "Key "
    puts Base64.encode64(packedKey)
    print "Encrypted "
    puts Base64.encode64(key.eta_encrypt(plaintext))
    print "-- done\n"
  end

end