require "bundler/setup"
require "universa"

include Universa

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  # config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |expectations|
    expectations.syntax = [:should, :expect]
  end
  config.mock_with :rspec do |mocks|
    mocks.syntax = :should
  end

  # Disable RSpec exposing methods globally on `Module` and `main`
  # config.disable_monkey_patching!

  # config.expect_with :rspec do |c|
  #   c.syntax = :should
  # end
end
