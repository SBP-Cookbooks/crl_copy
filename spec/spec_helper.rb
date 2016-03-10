require 'chefspec'
require 'chefspec/berkshelf'

RSpec.configure do |config|
  config.extend(ChefSpec::Cacher)

  config.platform = 'windows'
  config.version = '2012R2'
end

at_exit { ChefSpec::Coverage.report! }
