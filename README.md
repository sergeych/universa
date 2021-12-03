# Universa

This is an under-construction official gem from [Universa][universa] to facilitate access to the
Java library using Universa UMI protocol and Universa client services.

## News

- upgraded to new UMI (universa core is updated)
- unikeys cli tool now show information about public keys too
- unikeys extracts public keys and export as files or unversa text objects
  them as both univera binaries or universa text objects
- support to pack universa text objects, see [kb on universa text objects](https://kb.universablockchain.com/text_format_for_universa_objects/311).

## Old News :)

- production-tested in various universa projects
- rewritten Client and Connection to use new consensus-based, dns-free Universa network topology discovery protocol
- added syntax sugar for TransactionPack
- alfa version of the local FS-based contract store.
- ability to edit `contract.state` and `contract.transactional` in new revisions.
- fixed errors with interchange builder and set based objects
- ruby sugar for Universa native classes: Role, Adapter, Contract, Binder, HashId.
- Contract creation, revocation, changing owner in ruby way
- Network operation for white keys/private networks: parallel state check, contract recistration. 

This gem is already used in new Universa projects and is being actively tested.


## Installation

### Prerequisites

JVM v1.8.* must be installed.

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'universa'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install universa

## Usage

### Direct access to Universa objects:

~~~ruby
    include Universa

    @private_key = PrivateKey.new 2048
    c = Contract.create @private_key
    c.get_creator.get_all_addresses.should == [@private_key.long_address.to_s]
    c.seal()
    c.check() and c.trace_errors()
    c.should be_ok

    c1 = Contract.from_packed(c.packed)
    c1.hash_id.should == c.hash_id
    c1.should == c
    c1.expires_at.should > (Time.now + 120)
~~~

see smaples in specs (spec/contract_spec, spec/compound_spec, etc.)

### Direct access to UMI 
 
So far, you can only get direct access the the Java API functions. To get it:

```ruby
require 'universa'

umi = Universa::UMI.new

p umi.version                                         #=> "0.8.8"
key = umi.instantiate "PrivateKey", 2048
contract = umi.instantiate "Contract", key
sealed = contract.seal()
puts "Contract is ok: #{contract.check()}"            #=> contract is ok: true"
puts "Contract id: #{contract.getId.toBase64String}"  #=> contract id: x9Ey+q...

# ruby-style snake case could also be used:
contract_id = contract.get_id.to_base64_string 

```
## Docs and resources

for more information see:

- [Universa gem page](https://kb.universablockchain.com/universa_ruby_gem/131) in the Universa Knowledge Base.
- Universa Java API: https://kb.universablockchain.com/general_java_api/5 
- Universa UMI server: https://kb.universablockchain.com/umi_protocol/98
- Ruby [docs online](https://kb.universablockchain.com/system/static/gem_universa/)
- Farcall [gem](https://github.com/sergeych/farcall) and [protocol](https://github.com/sergeych/farcall/wiki).

### Use UMI service (alfa state)

The Universa::Service greatly simplify work taking all boilerplate. Just create objects almost as usual and use them
as is they are local:

```ruby
key = PrivateKey.new(open('mykey.private.unikey', 'rb').read)
contract = Contract.new(key)

contract.seal()
p contract.check()
```

The system will create UMI server and do all the work for you. Look at the RemoteAdapter class to see how does it
work. Soon we'll add adapters for all frequently used Universa classes.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/universa. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Universa project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/universa/blob/master/CODE_OF_CONDUCT.md).

[universa]:https://universablockchain.com
