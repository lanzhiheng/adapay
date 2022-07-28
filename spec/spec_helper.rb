# frozen_string_literal: true

require 'bundler/setup'
require 'adapay'
require 'openssl'
require 'base64'

Adapay.app_id = 'adapay_id'
Adapay.app_key = 'adapay_key'
Adapay.backup_app_id = 'adapay_backup_id'
Adapay.backup_app_key = 'adapay_backup_key'
# Private key which generate by your platform
Adapay.merchant_private_key = File.read('./spec/fixtures/merchant_private_key.pem')
# Public Key From Adapay Platform
Adapay.platform_public_key = File.read('./spec/fixtures/adapay_platform_public_key.pem')

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
