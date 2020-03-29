
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "universa/version"

Gem::Specification.new do |spec|
  spec.name          = "universa"
  spec.version       = Universa::VERSION
  spec.authors       = ["sergeych"]
  spec.email         = ["real.sergeych@gmail.com"]

  spec.summary       = %q{Expose Universa Java API to ruby}
  spec.description   = %q{Uses UMI Universa client}
  # spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "farcall", ">= 0.4.6"
  spec.add_dependency "boss-protocol", ">= 1.5.0"
  spec.add_dependency "concurrent-ruby", ">= 1.0.5"
  spec.add_dependency "concurrent-ruby-ext"
  spec.add_dependency "ansi"

  spec.add_development_dependency "bundler", "~> 2"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.8"
end
